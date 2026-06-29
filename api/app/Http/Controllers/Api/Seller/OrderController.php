<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
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

    // 1. GET /pemilik/orders
    public function index(Request $request)
    {
        try {
            $kantinId = $this->getKantinId();
            if (!$kantinId) {
                return response()->json(['success' => false, 'message' => 'Akses ditolak. Anda tidak terdaftar di kantin manapun.'], 403);
            }

            // Membangun query dasar
            $query = Pesanan::where('kantin_id', $kantinId)
                            ->with(['mahasiswa', 'details.menu', 'payment', 'kantin']);

            // FILTER: Tampilkan pesanan pengantaran hanya kepada kurir yang mengirimkannya, kecuali sudah selesai.
            // FILTER: Tampilkan pesanan (termasuk pemilik) kecuali jika pesanan pengantaran sudah diambil pegawai lain (dan belum selesai)
            $user = Auth::user();
            $query->where(function($q) use ($user) {
                $q->whereNull('courier_user_id')
                  ->orWhere('courier_user_id', $user->id)
                  ->orWhere('status_pesanan', 'selesai');
            });

            // FILTER: Berdasarkan status (baru, dimasak, selesai, dll)
            if ($request->has('status')) {
                $query->where('status_pesanan', $request->status);
            }

            // FILTER: Hanya ambil pesanan hari ini agar query tidak berat
            // (Kecuali jika user sengaja minta riwayat lama lewat parameter tanggal)
            if ($request->has('tanggal')) {
                $query->where(function($q) use ($request) {
                    $q->whereDate('created_at', $request->tanggal)
                      ->orWhereDate('updated_at', $request->tanggal);
                });
            } else {
                // Default: Tampilkan pesanan hari ini/diupdate hari ini ATAU pesanan yang belum selesai/dibatalkan
                $query->where(function($q) {
                    $q->whereDate('created_at', now()->toDateString())
                      ->orWhereDate('updated_at', now()->toDateString())
                      ->orWhereNotIn('status_pesanan', ['selesai', 'ditolak', 'dibatalkan']);
                });
            }

            // Eksekusi query (Urutkan dari yang paling baru)
            $orders = $query->latest()->get();

            // AMBIL DATA KANTIN UNTUK DIKIRIM KE FLUTTER
            $kantin = \App\Models\Kantin::find($kantinId);

            return response()->json([
                'success' => true,
                'data' => $orders,
                'kantin' => [
                    'nama_kantin' => $kantin->nama_kantin,
                    'status_toko' => $kantin->status_toko
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error getOrders: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Terjadi kesalahan pada server.'], 500);
        }
    }

    // 2. GET /pemilik/orders/{id}
    public function show($id)
    {
        try {
            $kantinId = $this->getKantinId();

            // AMAN: Cari pesanan TAPI wajib cocok dengan kantin_id
            $query = Pesanan::with(['mahasiswa', 'details.menu', 'payment', 'kantin'])
                            ->where('kantin_id', $kantinId);

            $user = Auth::user();
            $query->where(function($q) use ($user) {
                $q->whereNull('courier_user_id')
                  ->orWhere('courier_user_id', $user->id)
                  ->orWhere('status_pesanan', 'selesai');
            });

            $order = $query->find($id);

            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan atau bukan milik kantin Anda.'], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $order
            ]);

        } catch (\Exception $e) {
            Log::error('Error getOrderDetail: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Terjadi kesalahan pada server.'], 500);
        }
    }

    // 3. PATCH /pemilik/orders/{id}/status
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status_pesanan' => 'required|string',
        ]);

        try {
            $kantinId = $this->getKantinId();

            // AMAN: Pastikan pesanan adalah milik kantin ini
            $query = Pesanan::where('kantin_id', $kantinId);

            $user = Auth::user();
            $query->where(function($q) use ($user) {
                $q->whereNull('courier_user_id')
                  ->orWhere('courier_user_id', $user->id)
                  ->orWhere('status_pesanan', 'selesai');
            });

            $order = $query->find($id);

            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan atau bukan milik kantin Anda.'], 404);
            }

            // Update status pesanan
            $order->status_pesanan = $request->status_pesanan;
            
            // Simpan alasan penolakan jika dikirim dari Flutter (ditampung sementara di catatan_pesanan)
            if ($request->status_pesanan === 'ditolak' && $request->has('alasan_penolakan')) {
                $order->alasan_penolakan = $request->alasan_penolakan; 
            }

            $order->save();

            // Kirim notifikasi FCM ke mahasiswa
            try {
                $order->load('mahasiswa.user');
                if ($order->mahasiswa && $order->mahasiswa->user) {
                    $fcmService = app(\App\Services\FcmNotificationService::class);
                    $title = '';
                    $body = '';

                    switch ($order->status_pesanan) {
                        case 'menunggu_pembayaran':
                            $title = 'Pesanan Diterima';
                            $body = 'Pesanan Anda telah disetujui, silakan bayar';
                            break;
                        case 'dimasak':
                            $title = 'Pesanan Sedang Dimasak';
                            $body = 'Pembayaran dikonfirmasi! Pesanan Anda sedang dimasak.';
                            break;
                        case 'ditolak':
                            $title = 'Pesanan Ditolak';
                            $alasan = $order->alasan_penolakan ?? 'Bahan makanan habis';
                            $body = "Pesanan Anda ditolak: {$alasan}";
                            break;
                        case 'siap_diambil':
                            $title = 'Pesanan Siap!';
                            $body = 'Pesanan Anda siap diambil!';
                            break;
                        case 'dalam_perjalanan':
                        case 'menunggu_dikirim':
                            $title = 'Pesanan Sedang Dikirim';
                            $body = 'Pesanan Anda sedang dalam perjalanan / pengantaran.';
                            break;
                        case 'selesai':
                            $title = 'Pesanan Selesai';
                            $body = 'Pesanan Anda telah selesai, terima kasih!';
                            break;
                    }

                    if ($title !== '') {
                        $fcmService->sendToUser($order->mahasiswa->user, $title, $body);
                    }
                }
            } catch (\Throwable $e) {
                Log::error('FCM updateStatus notification error: ' . $e->getMessage());
            }

            // RETURN: Kita kembalikan data pesanan yang sudah di-update. 
            // Ini berguna agar Flutter tau nomor_antrian terbaru jika status berubah jadi 'dibayar'
            return response()->json([
                'success' => true,
                'message' => 'Status pesanan berhasil diperbarui',
                'data' => $order 
            ]);

        } catch (\Exception $e) {
            Log::error('Error updateOrderStatus: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Terjadi kesalahan saat memperbarui status.'], 500);
        }
    }
}