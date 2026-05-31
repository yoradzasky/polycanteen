<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Pesanan;
use App\Models\Ulasan;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class FinanceController extends Controller
{
    private const COMPLETED_ORDER_STATUS = 'selesai';
    private const PAID_PAYMENT_STATUS = 'sukses';

    public function __construct()
    {
        $this->middleware('auth:sanctum');
    }

    /**
     * GET /api/pemilik/finance/summary
     */
    public function summary(Request $request): JsonResponse
    {
        $authorization = $this->authorizePemilik();
        if ($authorization instanceof JsonResponse) {
            return $authorization;
        }

        $validated = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $kantinId = $authorization;
        [$from, $to] = $this->dateRange($validated);

        $completedOrders = $this->completedOrderQuery($kantinId, $from, $to);

        $totalRevenue = (clone $completedOrders)->sum('total_harga');
        $totalOrders = (clone $completedOrders)->count();
        $averageOrderValue = $totalOrders > 0 ? round($totalRevenue / $totalOrders, 2) : 0;

        $paidPayments = Payment::whereHas('pesanan', function ($query) use ($kantinId, $from, $to) {
            $query->where('kantin_id', $kantinId)
                ->where('status_pesanan', self::COMPLETED_ORDER_STATUS)
                ->whereBetween('created_at', [$from, $to]);
        })->where('status_bayar', self::PAID_PAYMENT_STATUS);

        $reviewStats = Ulasan::where('kantin_id', $kantinId)
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw('COUNT(*) as total_reviews, COALESCE(AVG(rating), 0) as average_rating')
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Ringkasan keuangan berhasil diambil.',
            'data' => [
                'period' => [
                    'from' => $from->toDateString(),
                    'to' => $to->toDateString(),
                ],
                'total_revenue' => (float) $totalRevenue,
                'total_completed_orders' => $totalOrders,
                'average_order_value' => $averageOrderValue,
                'paid_payment_total' => (float) (clone $paidPayments)->sum('nominal'),
                'paid_payment_count' => (clone $paidPayments)->count(),
                'total_reviews' => (int) ($reviewStats->total_reviews ?? 0),
                'average_rating' => round((float) ($reviewStats->average_rating ?? 0), 2),
            ],
        ]);
    }

    /**
     * GET /api/pemilik/finance/revenue
     */
    public function revenue(Request $request): JsonResponse
    {
        $authorization = $this->authorizePemilik();
        if ($authorization instanceof JsonResponse) {
            return $authorization;
        }

        $validated = $request->validate([
            'group_by' => ['nullable', Rule::in(['daily', 'monthly'])],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $kantinId = $authorization;
        $groupBy = $validated['group_by'] ?? 'daily';
        [$from, $to] = $this->dateRange($validated, $groupBy === 'monthly' ? 12 : 30);

        $dateExpression = $groupBy === 'monthly'
            ? "DATE_FORMAT(created_at, '%Y-%m')"
            : 'DATE(created_at)';

        $revenue = Pesanan::where('kantin_id', $kantinId)
            ->where('status_pesanan', self::COMPLETED_ORDER_STATUS)
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw("{$dateExpression} as period, COUNT(*) as total_orders, SUM(total_harga) as total_revenue")
            ->groupBy('period')
            ->orderBy('period')
            ->get()
            ->map(fn (Pesanan $row) => [
                'period' => $row->period,
                'total_orders' => (int) $row->total_orders,
                'total_revenue' => (float) $row->total_revenue,
            ]);

        return response()->json([
            'success' => true,
            'message' => 'Agregasi pendapatan berhasil diambil.',
            'data' => [
                'group_by' => $groupBy,
                'period' => [
                    'from' => $from->toDateString(),
                    'to' => $to->toDateString(),
                ],
                'items' => $revenue,
            ],
        ]);
    }

    /**
     * GET /api/pemilik/finance/withdrawals
     */
    public function withdrawals(Request $request): JsonResponse
    {
        $authorization = $this->authorizePemilik();
        if ($authorization instanceof JsonResponse) {
            return $authorization;
        }

        $validated = $request->validate([
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $kantinId = $authorization;
        [$from, $to] = $this->dateRange($validated);

        $payments = Payment::with(['pesanan:id,kantin_id,total_harga,status_pesanan,created_at'])
            ->where('status_bayar', self::PAID_PAYMENT_STATUS)
            ->whereHas('pesanan', function ($query) use ($kantinId, $from, $to) {
                $query->where('kantin_id', $kantinId)
                    ->where('status_pesanan', self::COMPLETED_ORDER_STATUS)
                    ->whereBetween('created_at', [$from, $to]);
            })
            ->latest('waktu_bayar')
            ->paginate($validated['per_page'] ?? 15);

        $payments->through(fn (Payment $payment) => [
            'id' => $payment->id,
            'pesanan_id' => $payment->pesanan_id,
            'nominal' => (float) ($payment->nominal ?? $payment->pesanan?->total_harga ?? 0),
            'metode_bayar' => $payment->metode_bayar,
            'status_bayar' => $payment->status_bayar,
            'status_pencairan' => 'available',
            'waktu_bayar' => $payment->waktu_bayar?->toISOString(),
            'midtrans_order_id' => $payment->midtrans_order_id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Riwayat pencairan dana berhasil diambil.',
            'data' => $payments,
        ]);
    }

    private function authorizePemilik(): int|JsonResponse
    {
        $user = Auth::user();

        if (! $user || $user->role !== 'pemilik') {
            return response()->json([
                'success' => false,
                'message' => 'Forbidden. Endpoint keuangan hanya dapat diakses oleh pemilik kantin.',
            ], 403);
        }

        $user->loadMissing('pemilik');

        if (! $user->pemilik?->kantin_id) {
            return response()->json([
                'success' => false,
                'message' => 'Kantin tidak ditemukan untuk akun pemilik ini.',
            ], 404);
        }

        return (int) $user->pemilik->kantin_id;
    }

    private function completedOrderQuery(int $kantinId, Carbon $from, Carbon $to)
    {
        return Pesanan::where('kantin_id', $kantinId)
            ->where('status_pesanan', self::COMPLETED_ORDER_STATUS)
            ->whereBetween('created_at', [$from, $to]);
    }

    private function dateRange(array $filters, int $defaultDays = 30): array
    {
        $from = isset($filters['from'])
            ? Carbon::parse($filters['from'])->startOfDay()
            : now()->subDays($defaultDays - 1)->startOfDay();

        $to = isset($filters['to'])
            ? Carbon::parse($filters['to'])->endOfDay()
            : now()->endOfDay();

        return [$from, $to];
    }
}
