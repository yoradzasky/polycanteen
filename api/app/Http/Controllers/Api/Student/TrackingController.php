<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;

class TrackingController extends Controller
{
    public function show(Request $request, Pesanan $pesanan)
    {
        $mahasiswaId = $request->user()->mahasiswa?->id;
        
        if (!$mahasiswaId || $pesanan->mahasiswa_id !== $mahasiswaId) {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        $pesanan->load(['mahasiswa', 'kantin', 'details.menu', 'courierUser.pegawai', 'courierUser.pemilik']);

        $orderItems = $pesanan->details->map(function ($detail) {
            return [
                'name' => $detail->menu->nama_item,
                'qty' => $detail->jumlah_pesanan,
            ];
        });

        return response()->json([
            'pesanan_id' => $pesanan->id,
            'queue_number' => $pesanan->nomor_antrian,
            'status' => $pesanan->status_pesanan,
            'courier_name' => $pesanan->courierUser?->courier_name,
            'buyer_name' => $pesanan->mahasiswa->nama_mahasiswa,
            'buyer_note' => $pesanan->catatan_pesanan,
            'origin' => [
                'label' => $pesanan->kantin->nama_kantin,
                'lat' => (float) $pesanan->kantin->latitude,
                'lng' => (float) $pesanan->kantin->longitude,
            ],
            'destination' => [
                'label' => $pesanan->alamat_pengantaran,
                'lat' => $pesanan->dest_lat ? (float) $pesanan->dest_lat : null,
                'lng' => $pesanan->dest_lng ? (float) $pesanan->dest_lng : null,
            ],
            'order_items' => $orderItems,
        ]);
    }
}
