<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ScannerController extends Controller
{
    /**
     * Mendapatkan ID Kantin dari user yang sedang login (Pemilik/Pegawai)
     */
    private function getKantinId()
    {
        $user = Auth::user();
        if ($user->pegawai) return $user->pegawai->kantin_id;
        if ($user->pemilik) return $user->pemilik->kantin_id;
        return null;
    }

    /**
     * POST /api/seller/scanner/verify
     *
     * Verifikasi QR code yang di-scan oleh penjual.
     * Mengambil data pesanan dan mengembalikan ringkasan untuk ditampilkan di layar.
     */
    public function verify(Request $request)
    {
        try {
            $request->validate([
                'qr_data' => 'required|string',
            ]);

            $kantinId = $this->getKantinId();
            if (!$kantinId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar di kantin manapun.',
                ], 403);
            }

            // Parse order ID dari QR string (format: "ORD-20240512" atau langsung angka)
            $qrData = trim($request->qr_data);
            $pesananId = null;

            // Coba parse format "ORD-{id}" atau "{id}"
            if (preg_match('/^ORD-(\d+)$/i', $qrData, $matches)) {
                $pesananId = (int) $matches[1];
            } elseif (is_numeric($qrData)) {
                $pesananId = (int) $qrData;
            }

            if (!$pesananId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Format QR code tidak valid. Pastikan QR code berasal dari aplikasi Polycanteen.',
                ], 422);
            }

            // Cari pesanan dengan eager-load relasi
            $pesanan = Pesanan::with(['mahasiswa', 'details.menu', 'payment'])
                ->find($pesananId);

            if (!$pesanan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak ditemukan.',
                ], 404);
            }

            // Validasi: pesanan harus milik kantin seller ini
            if ($pesanan->kantin_id !== $kantinId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan ini bukan milik kantin Anda.',
                ], 403);
            }

            // Hitung jumlah item dari detail pesanan
            $jumlahItem = $pesanan->details->sum('jumlah_pesanan');

            return response()->json([
                'success' => true,
                'data' => [
                    'pesanan_id' => $pesanan->id,
                    'nomor_antrian' => $pesanan->nomor_antrian,
                    'nama_pembeli' => $pesanan->mahasiswa->nama_mahasiswa ?? '-',
                    'jumlah_item' => $jumlahItem,
                    'total_harga' => $pesanan->total_harga,
                    'status_pesanan' => $pesanan->status_pesanan,
                    'tipe_pesanan' => $pesanan->tipe_pesanan,
                    'catatan_pesanan' => $pesanan->catatan_pesanan,
                    'created_at' => $pesanan->created_at,
                    'updated_at' => $pesanan->updated_at,
                    'details' => $pesanan->details->map(function ($detail) {
                        return [
                            'id' => $detail->id,
                            'jumlah_pesanan' => $detail->jumlah_pesanan,
                            'harga_saat_beli' => $detail->harga_saat_beli,
                            'subtotal' => $detail->subtotal,
                            'varian_snapshot' => $detail->varian_snapshot,
                            'menu' => [
                                'nama_item' => $detail->menu->nama_item ?? 'Item',
                            ],
                        ];
                    }),
                    'payment' => [
                        'metode_bayar' => $pesanan->payment->metode_bayar ?? '-',
                        'status_bayar' => $pesanan->payment->status_bayar ?? '-',
                    ]
                ],
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid: ' . $e->getMessage(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error scanner verify: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /**
     * POST /api/seller/scanner/confirm
     *
     * Konfirmasi pesanan — mengubah status dari "dibayar" menjadi "diproses".
     */
    public function confirm(Request $request)
    {
        try {
            $request->validate([
                'pesanan_id' => 'required|integer',
            ]);

            $kantinId = $this->getKantinId();
            if (!$kantinId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar di kantin manapun.',
                ], 403);
            }

            // Cari pesanan dan pastikan milik kantin ini
            $pesanan = Pesanan::where('kantin_id', $kantinId)
                ->find($request->pesanan_id);

            if (!$pesanan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak ditemukan atau bukan milik kantin Anda.',
                ], 404);
            }

            // Hanya bisa konfirmasi pesanan yang berstatus aktif/proses/siap diambil
            $allowedStatuses = ['dibayar', 'dikonfirmasi', 'diproses', 'dimasak', 'siap_diambil', 'dalam_perjalanan', 'menunggu_dikirim'];
            if (!in_array($pesanan->status_pesanan, $allowedStatuses)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak dapat dikonfirmasi. Status saat ini: ' . $pesanan->status_pesanan,
                ], 422);
            }

            $oldStatus = $pesanan->status_pesanan;
            if ($oldStatus === 'dibayar') {
                $pesanan->status_pesanan = 'diproses';
                $message = 'Pesanan berhasil dikonfirmasi';

                try {
                    $pesanan->load('mahasiswa.user');
                    if ($pesanan->mahasiswa && $pesanan->mahasiswa->user) {
                        $fcmService = app(\App\Services\FcmNotificationService::class);
                        $fcmService->sendToUser(
                            $pesanan->mahasiswa->user,
                            'Pesanan Diproses',
                            'Pesanan Anda sedang diproses oleh penjual.'
                        );
                    }
                } catch (\Throwable $e) {
                    Log::error('FCM confirm (diproses) error: ' . $e->getMessage());
                }
            } else {
                $pesanan->status_pesanan = 'selesai';
                $message = 'Pesanan berhasil diselesaikan';

                try {
                    $pesanan->load('mahasiswa.user');
                    if ($pesanan->mahasiswa && $pesanan->mahasiswa->user) {
                        $fcmService = app(\App\Services\FcmNotificationService::class);
                        $fcmService->sendToUser(
                            $pesanan->mahasiswa->user,
                            'Pesanan Selesai',
                            'Pesanan Anda telah selesai, terima kasih!'
                        );
                    }
                } catch (\Throwable $e) {
                    Log::error('FCM confirm (selesai) error: ' . $e->getMessage());
                }
            }
            $pesanan->save();

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => [
                    'pesanan_id' => $pesanan->id,
                    'nomor_antrian' => $pesanan->nomor_antrian,
                    'status_pesanan' => $pesanan->status_pesanan,
                ],
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid: ' . $e->getMessage(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error scanner confirm: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat mengkonfirmasi pesanan.',
            ], 500);
        }
    }
}
