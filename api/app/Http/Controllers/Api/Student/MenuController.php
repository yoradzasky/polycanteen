<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use Illuminate\Http\JsonResponse;

class MenuController extends Controller
{
    /**
     * Menampilkan daftar menu berdasarkan ID kantin beserta rating ulasannya.
     */
    public function index($kantinId): JsonResponse
    {
        try {
            $menus = Menu::where('kantin_id', $kantinId)
                         // Menghitung rata-rata rating dan jumlah ulasan menu secara otomatis
                         ->withAvg('ulasan', 'rating')
                         ->withCount('ulasan')
                         ->orderBy('kategori', 'asc')
                         ->get();

            return response()->json($menus, 200);

        } catch (\Exception $e) {
            // Wajib mengembalikan JsonResponse jika terjadi error
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat mengambil data menu.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}