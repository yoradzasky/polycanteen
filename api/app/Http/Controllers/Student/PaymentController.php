<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Midtrans\Config;
use Midtrans\Snap;

class PaymentController extends Controller
{
    public function __construct()
    {
        Config::$serverKey = config('midtrans.server_key');
        Config::$isProduction = config('midtrans.is_production');
        Config::$isSanitized = config('midtrans.is_sanitized');
        Config::$is3ds = config('midtrans.is_3ds');
    }

    public function createPayment(Request $request, $pesanan_id)
    {
        $pesanan = Pesanan::with('mahasiswa', 'pesanan_detail')->findOrFail($pesanan_id);

        if ($pesanan->status_pembayaran === 'dibayar') {
            return response()->json([
                'success' => false,
                'message' => 'Pesanan ini sudah dibayar.'
            ], 400);
        }

        $params = [
            'transaction_details' => [
                'order_id' => $pesanan->id . '-' . time(), // Dibuat unik
                'gross_amount' => $pesanan->total_harga,
            ],
            'customer_details' => [
                'first_name' => $pesanan->mahasiswa->nama,
                'email' => $pesanan->mahasiswa->email,
            ],
        ];

        try {
            // Dapatkan Snap Token & URL dari Midtrans
            $snapToken = Snap::getSnapToken($params);
            $paymentUrl = Snap::createTransaction($params)->redirect_url;

            $pesanan->update([
                'snap_token' => $snapToken,
                'payment_url' => $paymentUrl
            ]);

            return response()->json([
                'success' => true,
                'data' => [
                    'snap_token' => $snapToken,
                    'payment_url' => $paymentUrl
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}