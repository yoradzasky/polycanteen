<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use App\Models\Ulasan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ReviewController extends Controller
{
    /**
     * Mendapatkan ID Mahasiswa dari user yang sedang login.
     */
    private function getMahasiswaId()
    {
        return Auth::user()->mahasiswa?->id;
    }

    /**
     * POST /mahasiswa/reviews
     * Membuat ulasan baru untuk pesanan yang sudah selesai.
     */
    public function store(Request $request)
    {
        try {
            $mahasiswaId = $this->getMahasiswaId();
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            $request->validate([
                'pesanan_id' => 'required|integer|exists:pesanan,id',
                'rating'     => 'required|integer|min:1|max:5',
                'komentar'   => 'nullable|string|max:500',
            ]);

            // Pastikan pesanan milik mahasiswa yang login
            $pesanan = Pesanan::with('details')
                ->where('id', $request->pesanan_id)
                ->where('mahasiswa_id', $mahasiswaId)
                ->first();

            if (!$pesanan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak ditemukan atau bukan milik Anda.',
                ], 404);
            }

            // Pastikan pesanan sudah selesai
            if ($pesanan->status_pesanan !== 'selesai') {
                return response()->json([
                    'success' => false,
                    'message' => 'Ulasan hanya bisa diberikan untuk pesanan yang sudah selesai.',
                ], 422);
            }

            // Pastikan belum ada ulasan
            if ($pesanan->ulasan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda sudah memberikan ulasan untuk pesanan ini.',
                ], 422);
            }

            $firstDetail = $pesanan->details->first();
            $menuId = $firstDetail ? $firstDetail->menu_id : null;

            if (!$menuId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pesanan tidak memiliki detail menu untuk diulas.',
                ], 422);
            }

            $ulasan = Ulasan::create([
                'pesanan_id'   => $pesanan->id,
                'mahasiswa_id' => $mahasiswaId,
                'kantin_id'    => $pesanan->kantin_id,
                'menu_id'      => $menuId,
                'rating'       => $request->rating,
                'komentar'     => $request->komentar,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Ulasan berhasil dikirim. Terima kasih!',
                'data'    => $ulasan,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak valid.',
                'errors'  => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error storeReview: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan pada server.',
            ], 500);
        }
    }
}
