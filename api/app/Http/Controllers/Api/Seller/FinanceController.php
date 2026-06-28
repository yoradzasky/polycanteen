<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class FinanceController extends Controller
{
    /**
     * Mendapatkan ID Kantin dari user yang sedang login (Pemilik)
     */
    private function getKantinId()
    {
        $user = Auth::user();
        if ($user->pemilik) return $user->pemilik->kantin_id;
        return null;
    }

    /**
     * Validasi Role. Pastikan hanya 'pemilik'
     */
    private function checkRole()
    {
        $user = Auth::user();
        return $user->role === 'pemilik';
    }

    /**
     * 1. GET /pemilik/finance/summary
     */
    public function summary(Request $request)
    {
        if (!$this->checkRole()) {
            return response()->json([
                'success' => false, 
                'message' => 'Akses ditolak. Hanya pemilik yang dapat melihat fitur ini.'
            ], 403);
        }

        try {
            $kantinId = $this->getKantinId();
            if (!$kantinId) {
                return response()->json(['success' => false, 'message' => 'Anda tidak terdaftar di kantin manapun.'], 403);
            }

            $today = now()->toDateString();
            $month = now()->format('Y-m');

            // Agregasi Harian (menggunakan updated_at untuk menandakan waktu selesai)
            $dailyRevenue = Pesanan::where('kantin_id', $kantinId)
                ->where('status_pesanan', 'selesai')
                ->whereDate('updated_at', $today)
                ->sum('total_harga');

            // Agregasi Bulanan
            $monthlyRevenue = Pesanan::where('kantin_id', $kantinId)
                ->where('status_pesanan', 'selesai')
                ->where('updated_at', 'like', $month . '%')
                ->sum('total_harga');

            // Agregasi Keseluruhan
            $totalRevenue = Pesanan::where('kantin_id', $kantinId)
                ->where('status_pesanan', 'selesai')
                ->sum('total_harga');

            return response()->json([
                'success' => true,
                'data' => [
                    'daily_revenue' => (double) $dailyRevenue,
                    'monthly_revenue' => (double) $monthlyRevenue,
                    'total_revenue' => (double) $totalRevenue,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error FinanceSummary: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Terjadi kesalahan pada server.'], 500);
        }
    }

    /**
     * 2. GET /pemilik/finance/history
     */
    public function history(Request $request)
    {
        if (!$this->checkRole()) {
            return response()->json([
                'success' => false, 
                'message' => 'Akses ditolak. Hanya pemilik yang dapat melihat fitur ini.'
            ], 403);
        }

        try {
            $kantinId = $this->getKantinId();
            if (!$kantinId) {
                return response()->json(['success' => false, 'message' => 'Anda tidak terdaftar di kantin manapun.'], 403);
            }

            $query = Pesanan::with(['payment', 'mahasiswa', 'ulasan', 'details.menu'])
                ->where('kantin_id', $kantinId)
                ->where('status_pesanan', 'selesai');

            // Filter tanggal jika ada
            if ($request->has('tanggal')) {
                $query->whereDate('updated_at', $request->tanggal);
            }

            // Ambil data terbaru berdasarkan update (saat status menjadi selesai)
            $history = $query->latest('updated_at')->get();

            return response()->json([
                'success' => true,
                'data' => $history
            ]);
        } catch (\Exception $e) {
            Log::error('Error FinanceHistory: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Terjadi kesalahan pada server.'], 500);
        }
    }
}
