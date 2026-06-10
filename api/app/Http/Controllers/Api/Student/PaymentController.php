<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Midtrans\Config;
use Midtrans\Snap;
use Midtrans\CoreApi;

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
        $pesanan = Pesanan::with('mahasiswa', 'details')->findOrFail($pesanan_id);

        if ($pesanan->status_pesanan === 'dibayar') {
            return response()->json([
                'success' => false,
                'message' => 'Pesanan ini sudah dibayar.'
            ], 400);
        }

        $paymentType = $request->input('payment_type'); // 'qris' atau 'va'

        // DEFAULT PARAMS
        $params = [
            'transaction_details' => [
                'order_id' => $pesanan->id . '-' . time(),
                'gross_amount' => (int) round($pesanan->total_harga),
            ],
            'customer_details' => [
                'first_name' => $pesanan->mahasiswa->nama,
                'email' => $pesanan->mahasiswa->email,
            ],
        ];

        try {
            if ($paymentType === 'qris') {
                // MENGGUNAKAN CORE API UNTUK QRIS
                $params['payment_type'] = 'qris';
                
                $response = CoreApi::charge($params);

                // Ambil QR String dari response actions
                $qrString = null;
                if (isset($response->actions)) {
                    foreach ($response->actions as $action) {
                        if ($action->name === 'generate-qr-code') {
                            $qrString = $action->url;
                            break;
                        }
                    }
                }

                return response()->json([
                    'success' => true,
                    'data' => [
                        'payment_type' => 'qris',
                        'qr_string' => $qrString,
                        'transaction_id' => $response->transaction_id ?? null,
                        'order_id' => $response->order_id ?? null,
                        'gross_amount' => $response->gross_amount ?? null,
                        'expiry_time' => $response->expiry_time ?? null,
                    ]
                ]);
            } else {
                // MENGGUNAKAN SNAP UNTUK VA / LAINNYA
                $enabledPayments = ['bank_transfer'];
                if ($paymentType === 'va') {
                    $enabledPayments = ['bank_transfer'];
                } else {
                    $enabledPayments = ['qris', 'gopay', 'other_qris', 'bank_transfer'];
                }

                $params['enabled_payments'] = $enabledPayments;
                $snapToken = Snap::getSnapToken($params);
                $paymentUrl = Snap::createTransaction($params)->redirect_url;

                return response()->json([
                    'success' => true,
                    'data' => [
                        'payment_type' => 'snap',
                        'snap_token' => $snapToken,
                        'payment_url' => $paymentUrl
                    ]
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}
