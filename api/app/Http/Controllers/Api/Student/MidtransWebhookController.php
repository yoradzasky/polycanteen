<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;

class MidtransWebhookController extends Controller
{
    public function handle(Request $request)
    {
        $serverKey = config('midtrans.server_key');
        $hashed = hash("sha512", $request->order_id . $request->status_code . $request->gross_amount . $serverKey);

        if ($hashed !== $request->signature_key) {
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        $transactionStatus = $request->transaction_status;
        $orderIdParts = explode('-', $request->order_id);
        $realOrderId = $orderIdParts[0]; // Mengambil ID asli pesanan

        $pesanan = Pesanan::find($realOrderId);
        if (!$pesanan) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        if ($transactionStatus == 'capture' || $transactionStatus == 'settlement') {
            $pesanan->status_pesanan = 'dibayar';
        } elseif ($transactionStatus == 'cancel' || $transactionStatus == 'deny' || $transactionStatus == 'expire') {
            $pesanan->status_pesanan = 'gagal';
        } elseif ($transactionStatus == 'pending') {
            $pesanan->status_pesanan = 'pending';
        }

        $pesanan->save();

        return response()->json(['message' => 'Webhook success']);
    }
}