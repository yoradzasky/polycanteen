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
            $query->where(function($q) {
                $user = Auth::user();
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
                $query->whereDate('created_at', $request->tanggal);
            } else {
                // Default: Tampilkan pesanan hari ini saja
                $query->whereDate('created_at', now()->toDateString());
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
            $order = Pesanan::with(['mahasiswa', 'details.menu', 'payment', 'kantin'])
                            ->where('kantin_id', $kantinId)
                            ->where(function($q) {
                                $user = Auth::user();
                                $q->whereNull('courier_user_id')
                                  ->orWhere('courier_user_id', $user->id)
                                  ->orWhere('status_pesanan', 'selesai');
                            })
                            ->find($id);

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
            $order = Pesanan::where('kantin_id', $kantinId)
                            ->where(function($q) {
                                $user = Auth::user();
                                $q->whereNull('courier_user_id')
                                  ->orWhere('courier_user_id', $user->id)
                                  ->orWhere('status_pesanan', 'selesai');
                            })
                            ->find($id);

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