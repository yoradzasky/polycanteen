<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;

use App\Models\Payment;
use Illuminate\Support\Facades\DB;

class MidtransWebhookController extends Controller
{
    public function handle(Request $request)
    {
        $serverKey = config('midtrans.server_key');
        
        // Log request untuk debugging
        \Log::info('Midtrans Webhook Received:', $request->all());

        // Pastikan gross_amount diformat dengan benar (terkadang midtrans mengirimkan .00)
        $grossAmount = str_replace('.00', '', $request->gross_amount);
        $hashed = hash("sha512", $request->order_id . $request->status_code . $request->gross_amount . $serverKey);
        $hashedWithFormatted = hash("sha512", $request->order_id . $request->status_code . $grossAmount . $serverKey);

        // Cek keduanya untuk jaga-jaga
        if ($hashed !== $request->signature_key && $hashedWithFormatted !== $request->signature_key) {
            \Log::error('Midtrans Webhook Invalid Signature', [
                'received' => $request->signature_key,
                'expected1' => $hashed,
                'expected2' => $hashedWithFormatted
            ]);
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $transactionStatus = $request->transaction_status;
        $orderIdParts = explode('-', $request->order_id);
        $realOrderId = $orderIdParts[0];

        // Cek jika ini adalah notifikasi test dari dashboard Midtrans
        if (str_contains($request->order_id, 'test')) {
            \Log::info('Midtrans Test Webhook Received and Ignored');
            return response()->json(['message' => 'Test webhook success']);
        }

        $pesanan = Pesanan::find($realOrderId);
        if (!$pesanan) {
            \Log::error('Midtrans Webhook Order Not Found: ' . $realOrderId);
            // Tetap return 200 agar Midtrans tidak terus mencoba mengirim ulang 
            // atau menganggap URL mati, tapi kita log error-nya.
            return response()->json(['message' => 'Order not found but acknowledged'], 200);
        }

        try {
            DB::transaction(function () use ($pesanan, $transactionStatus, $request) {
                // Update Tabel Pesanan
                if ($transactionStatus == 'capture' || $transactionStatus == 'settlement') {
                    $pesanan->status_pesanan = 'dimasak';
                } elseif ($transactionStatus == 'cancel' || $transactionStatus == 'deny' || $transactionStatus == 'expire') {
                    $pesanan->status_pesanan = 'gagal';
                } elseif ($transactionStatus == 'pending') {
                    $pesanan->status_pesanan = 'menunggu_pembayaran';
                }
                $pesanan->save();

                // Update Tabel Payment (Penting agar checkStatus membaca data terbaru)
                Payment::updateOrCreate(
                    ['pesanan_id' => $pesanan->id],
                    [
                        'status_bayar' => ($transactionStatus == 'capture' || $transactionStatus == 'settlement') ? 'sukses' : 
                                         (($transactionStatus == 'pending') ? 'pending' : 'gagal'),
                        'metode_bayar' => $request->payment_type ?? 'midtrans',
                        'log_transaksi' => json_encode($request->all()),
                        'nominal' => (int) str_replace('.00', '', $request->gross_amount),
                        'waktu_bayar' => now(),
                        'midtrans_order_id' => $request->order_id,
                    ]
                );
            });
            
            \Log::info('Midtrans Webhook Success for Order ID: ' . $realOrderId);
        } catch (\Exception $e) {
            \Log::error('Midtrans Webhook Database Error: ' . $e->getMessage());
            return response()->json(['message' => 'Internal Server Error'], 500);
        }

        return response()->json(['message' => 'Webhook success']);
    }
}