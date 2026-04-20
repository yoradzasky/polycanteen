<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Midtrans\Config;
use Midtrans\Snap;

class PaymentController extends Controller
{
    public function getToken(Request $request) 
    {
        // 1. Konfigurasi Midtrans
        Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        Config::$isProduction = env('MIDTRANS_IS_PRODUCTION');
        Config::$isSanitized = true;
        Config::$is3ds = true;

        // 2. Parameter Transaksi
        $params = [
            'transaction_details' => [
                'order_id' => 'POLY-' . uniqid(), // ID pesanan unik
                'gross_amount' => $request->total_harga,
            ],
            'customer_details' => [
                'first_name' => $request->nama_mahasiswa,
                'email' => $request->email,
            ],
            
        ];

        // 3. Generate Snap Token
        try {
            $snapToken = Snap::getSnapToken($params);
            return response()->json(['token' => $snapToken]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function callback(Request $request)
    {
        $serverKey = env('MIDTRANS_SERVER_KEY');
        
        // 1. Verifikasi Signature Key (Keamanan)
        $hashed = hash("sha512", $request->order_id . $request->status_code . $request->gross_amount . $serverKey);
        if ($hashed !== $request->signature_key) {
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        // 2. Ambil data transaksi dari Midtrans
        $transactionStatus = $request->transaction_status;
        $orderId = $request->order_id; 

        // 3. Logika Update Status di Database
        // Contoh: $order = Order::where('id_order', $orderId)->first(); 

        if ($transactionStatus == 'settlement') {
            // Pembayaran Sukses
            // Update tabel Order: status_pesanan = 'Diterima'
            // Update tabel Payment: status_bayar = 'Sukses'
        } else if ($transactionStatus == 'pending') {
            // Menunggu Pembayaran
        } else if (in_array($transactionStatus, ['deny', 'expire', 'cancel'])) {
            // Pembayaran Gagal
            // Update tabel Payment: status_bayar = 'Gagal'
        }

        return response()->json(['message' => 'Callback handled successfully']);
    }
}