<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Kantin;
use Illuminate\Http\JsonResponse;

class KantinController extends Controller
{
    /**
     * Menampilkan daftar seluruh kantin untuk mahasiswa.
     */
    public function index(): JsonResponse
    {
        try {
            // Mengambil semua kantin
            // withAvg('nama_relasi', 'nama_kolom') -> menghasilkan ulasan_avg_rating
            // withCount('nama_relasi') -> menghasilkan ulasan_count
            $kantins = Kantin::withAvg('ulasan', 'rating')
                             ->withCount('ulasan')
                             ->get();

            // Return langsung sebagai JSON array agar sesuai dengan parsing di Flutter
            return response()->json($kantins, 200);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Terjadi kesalahan saat mengambil data kantin.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}