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
                'dibayar',
                'dikonfirmasi',
                'diproses',
                'dimasak',
                'siap_diambil',
                'menunggu_dikirim',
                'dalam_perjalanan'
            ];
            $statusRiwayat = ['selesai', 'ditolak', 'dibatalkan'];

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
}
