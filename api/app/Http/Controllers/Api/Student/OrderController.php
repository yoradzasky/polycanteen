<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
{
    /**
     * Mendapatkan ID Mahasiswa dari user yang sedang login.
     */
    private function getMahasiswaId()
    {
        return Auth::user()->mahasiswa?->id;
    }

    /**
     * 1. GET /mahasiswa/orders
     * Mengembalikan pesanan aktif (dalam_proses) dan riwayat (selesai/ditolak/dibatalkan).
     */
    public function index()
    {
        try {
            $mahasiswaId = $this->getMahasiswaId();
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            $eagerLoad = [
                'kantin:id,nama_kantin,logo_path',
                'details.menu:id,nama_item,foto_menu',
                'payment:id,pesanan_id,status_bayar,metode_bayar',
                'ulasan:id,pesanan_id,rating',
            ];

            $statusAktif = [
                'pending',
                'menunggu_persetujuan',
                'menunggu_pembayaran',
                'dibayar',
                'dikonfirmasi',
                'diproses',
                'dimasak',
                'siap_diambil',
                'menunggu_dikirim',
                'dalam_perjalanan'
            ];
            $statusRiwayat = ['selesai', 'ditolak', 'dibatalkan', 'gagal'];

            $dalamProses = Pesanan::where('mahasiswa_id', $mahasiswaId)
                ->whereIn('status_pesanan', $statusAktif)
                ->with($eagerLoad)
                ->latest()
                ->get();

            $riwayat = Pesanan::where('mahasiswa_id', $mahasiswaId)
                ->whereIn('status_pesanan', $statusRiwayat)
                ->with($eagerLoad)
                ->latest()
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'dalam_proses' => $dalamProses,
                    'riwayat' => $riwayat,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Error getStudentOrders: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /**
     * 2. GET /mahasiswa/orders/{id}
     * Mengembalikan detail satu pesanan milik mahasiswa yang login.
     */
    public function show($id)
    {
        try {
            $mahasiswaId = $this->getMahasiswaId();
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            $pesanan = Pesanan::with([
                    'kantin:id,nama_kantin,logo_path',
                    'details.menu:id,nama_item,foto_menu',
                    'payment:id,pesanan_id,status_bayar,metode_bayar',
                    'ulasan',
                    'courierUser',
                ])
                ->where('mahasiswa_id', $mahasiswaId)
                ->find($id);

            if (!$pesanan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak ditemukan atau bukan milik Anda.',
                ], 404);
            }


            // Format response sesuai spesifikasi
            $details = $pesanan->details->map(function ($detail) {
                return [
                    'id'              => $detail->id,
                    'menu_id'         => $detail->menu_id,
                    'nama_item'       => $detail->menu->nama_item ?? '-',
                    'foto_menu'       => $detail->menu->foto_menu ?? null,
                    'jumlah_pesanan'  => $detail->jumlah_pesanan,
                    'harga_saat_beli' => $detail->harga_saat_beli,
                    'subtotal'        => $detail->subtotal,
                    'varian_snapshot' => $detail->varian_snapshot,
                    'topping_snapshot'=> $detail->topping_snapshot,
                ];
            })->values();

            return response()->json([
                'success' => true,
                'data' => [
                    'id'              => $pesanan->id,
                    'nomor_antrian'   => $pesanan->nomor_antrian,
                    'status_pesanan'  => $pesanan->status_pesanan,
                    'tipe_pesanan'    => $pesanan->tipe_pesanan,
                    'total_harga'     => $pesanan->total_harga,
                    'catatan_pesanan' => $pesanan->catatan_pesanan,
                    'qr_token'        => $pesanan->qr_token,
                    'kantin' => [
                        'nama_kantin' => $pesanan->kantin->nama_kantin ?? '-',
                        'logo_path'   => $pesanan->kantin->logo_path ?? null,
                    ],
                    'details'  => $details,
                    'payment'  => $pesanan->payment ? [
                        'status_bayar' => $pesanan->payment->status_bayar,
                        'metode_bayar' => $pesanan->payment->metode_bayar,
                    ] : null,
                    'ulasan'     => $pesanan->ulasan,
                    'created_at' => $pesanan->created_at,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Error getStudentOrderDetail: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }

    /**
     * 3. PATCH /mahasiswa/orders/{id}/submit
     * Mengajukan pesanan dengan tipe pesanan, alamat, koordinat, catatan, dan status pending.
     */
    public function submitOrder(Request $request, $id)
    {
        try {
            $mahasiswaId = $this->getMahasiswaId();
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            $pesanan = Pesanan::where('mahasiswa_id', $mahasiswaId)->findOrFail($id);

            $validated = $request->validate([
                'tipe_pesanan' => 'required|string',
                'alamat_pengantaran' => 'nullable|string',
                'dest_lat' => 'nullable|numeric',
                'dest_lng' => 'nullable|numeric',
                'catatan_pesanan' => 'nullable|string',
            ]);

            // Map tipe pesanan dari Flutter ke database format
            $tipe = 'dine_in';
            $inputTipe = strtolower($validated['tipe_pesanan']);
            if (str_contains($inputTipe, 'makan di tempat') || $inputTipe === 'dine_in') {
                $tipe = 'dine_in';
            } elseif (str_contains($inputTipe, 'bungkus') || $inputTipe === 'take_away' || $inputTipe === 'takeaway') {
                $tipe = 'take_away';
            } elseif (str_contains($inputTipe, 'pengantaran') || $inputTipe === 'delivery') {
                $tipe = 'delivery';
            }

            $pesanan->update([
                'tipe_pesanan' => $tipe,
                'alamat_pengantaran' => $validated['alamat_pengantaran'] ?? null,
                'dest_lat' => $validated['dest_lat'] ?? null,
                'dest_lng' => $validated['dest_lng'] ?? null,
                'catatan_pesanan' => $validated['catatan_pesanan'] ?? $pesanan->catatan_pesanan,
                'status_pesanan' => 'menunggu_persetujuan', // Set status to menunggu_persetujuan
            ]);

            // Kirim notifikasi FCM ke penjual
            try {
                $fcmService = app(\App\Services\FcmNotificationService::class);
                $mahasiswaNama = Auth::user()->mahasiswa?->nama_mahasiswa ?? Auth::user()->nama_lengkap;
                $fcmService->sendToKantinOwners(
                    $pesanan->kantin_id,
                    'Pesanan Baru!',
                    "Ada pesanan baru dari {$mahasiswaNama}."
                );
            } catch (\Throwable $e) {
                Log::error('FCM new order notification error: ' . $e->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Pesanan berhasil diajukan, menunggu persetujuan penjual.',
                'data' => $pesanan
            ]);
        } catch (\Exception $e) {
            Log::error('Error submitOrder: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat memproses pesanan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * 4. PATCH /mahasiswa/orders/{id}/cancel
     * Membatalkan pesanan sebelum disetujui penjual.
     */
    public function cancelOrder(Request $request, $id)
    {
        try {
            $mahasiswaId = $this->getMahasiswaId();
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            $pesanan = Pesanan::where('mahasiswa_id', $mahasiswaId)->findOrFail($id);

            // Cancel only if status is pending or menunggu_persetujuan
            if (!in_array($pesanan->status_pesanan, ['pending', 'menunggu_persetujuan'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak dapat dibatalkan pada status saat ini.',
                ], 400);
            }

            $pesanan->update([
                'status_pesanan' => 'dibatalkan',
            ]);

            // Kirim notifikasi FCM ke pemilik & pegawai kantin
            try {
                $fcmService = app(\App\Services\FcmNotificationService::class);
                $mahasiswaNama = Auth::user()->mahasiswa?->nama_mahasiswa ?? Auth::user()->nama_lengkap;
                $fcmService->sendToKantinOwners(
                    $pesanan->kantin_id,
                    'Pesanan Dibatalkan',
                    "Pesanan dari {$mahasiswaNama} telah dibatalkan oleh pembeli."
                );
            } catch (\Throwable $e) {
                Log::error('FCM Cancel Notification Error: ' . $e->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Pesanan berhasil dibatalkan.',
                'data' => $pesanan
            ]);
        } catch (\Exception $e) {
            Log::error('Error cancelOrder: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat membatalkan pesanan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * 5. PATCH /mahasiswa/orders/{id}/items
     * Mengupdate jumlah item pesanan selama status pesanan masih pending.
     */
    public function updateItemQuantity(Request $request, $id)
    {
        try {
            $mahasiswaId = $this->getMahasiswaId();
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            $validated = $request->validate([
                'detail_id' => 'required|exists:pesanan_detail,id',
                'action' => 'required|in:increase,decrease',
            ]);

            $pesanan = Pesanan::where('mahasiswa_id', $mahasiswaId)->findOrFail($id);

            // Update only if status is pending
            if ($pesanan->status_pesanan !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak dapat diubah setelah diajukan.',
                ], 400);
            }

            $detail = \App\Models\PesananDetail::where('pesanan_id', $pesanan->id)
                ->findOrFail($validated['detail_id']);

            \Illuminate\Support\Facades\DB::beginTransaction();

            if ($validated['action'] === 'increase') {
                $detail->jumlah_pesanan += 1;
                $detail->subtotal = $detail->harga_saat_beli * $detail->jumlah_pesanan;
                $detail->save();
            } else {
                if ($detail->jumlah_pesanan > 1) {
                    $detail->jumlah_pesanan -= 1;
                    $detail->subtotal = $detail->harga_saat_beli * $detail->jumlah_pesanan;
                    $detail->save();
                } else {
                    $detail->delete();
                }
            }

            // Hitung ulang total_harga pesanan
            $totalHarga = \App\Models\PesananDetail::where('pesanan_id', $pesanan->id)->sum('subtotal');
            
            if ($totalHarga == 0) {
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak boleh kosong. Gunakan tombol Batal jika ingin membatalkan.',
                ], 400);
            }

            $pesanan->total_harga = $totalHarga + 1000;
            $pesanan->save();

            // Hitung nominal pembayaran
            if ($pesanan->payment) {
                $pesanan->payment->nominal = $totalHarga + 1000;
                $pesanan->payment->save();
            }

            \Illuminate\Support\Facades\DB::commit();

            // Refresh data pesanan & details
            $pesanan->load(['details.menu', 'payment']);

            $details = $pesanan->details->map(function ($d) {
                return [
                    'id'              => $d->id,
                    'menu_id'         => $d->menu_id,
                    'nama_item'       => $d->menu->nama_item ?? '-',
                    'foto_menu'       => $d->menu->foto_menu ?? null,
                    'jumlah_pesanan'  => $d->jumlah_pesanan,
                    'harga_saat_beli' => $d->harga_saat_beli,
                    'subtotal'        => $d->subtotal,
                    'varian_snapshot' => $d->varian_snapshot,
                    'topping_snapshot'=> $d->topping_snapshot,
                ];
            })->values();

            return response()->json([
                'success' => true,
                'message' => 'Jumlah item berhasil diupdate.',
                'data' => [
                    'id'              => $pesanan->id,
                    'total_harga'     => $pesanan->total_harga,
                    'details'         => $details,
                ]
            ]);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            Log::error('Error updateItemQuantity: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat mengupdate item pesanan: ' . $e->getMessage(),
            ], 500);
        }
    }
}

