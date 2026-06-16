<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Kreait\Firebase\Contract\Database;

class DeliveryController extends Controller
{
    protected Database $database;

    public function __construct(Database $database)
    {
        $this->database = $database;
    }

    public function start(Request $request, Pesanan $pesanan)
    {
        $user = $request->user();
        if (!in_array($user->role, ['pegawai', 'pemilik'])) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $pesanan->load(['mahasiswa', 'kantin', 'details.menu']);

        if ($pesanan->status_pesanan !== 'menunggu_dikirim') {
            return response()->json(['message' => 'Status pesanan harus menunggu_dikirim'], 422);
        }

        $pesanan->update([
            'courier_user_id' => $user->id,
            'status_pesanan' => 'dalam_perjalanan',
            'qr_token' => Str::uuid()->toString(),
        ]);

        $this->database->getReference('deliveries/' . $pesanan->id . '/location')
            ->set([
                'lat' => (float) $pesanan->kantin->latitude,
                'lng' => (float) $pesanan->kantin->longitude,
                'updated_at' => (int) (now()->timestamp * 1000),
            ]);

        return response()->json([
            'message' => 'Pengantaran dimulai',
            'pesanan_id' => $pesanan->id,
        ]);
    }

    public function show(Request $request, Pesanan $pesanan)
    {
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

    public function confirm(Request $request, Pesanan $pesanan)
    {
        $user = $request->user();
        if (!in_array($user->role, ['pegawai', 'pemilik'])) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'qr_token' => 'required|string',
        ]);

        if ($pesanan->qr_token !== $request->qr_token) {
            return response()->json(['message' => 'QR Token tidak valid'], 403);
        }

        $pesanan->update([
            'status_pesanan' => 'selesai',
        ]);

        $this->database->getReference('deliveries/' . $pesanan->id)->remove();

        return response()->json([
            'message' => 'Pesanan dikonfirmasi',
        ]);
    }
}
