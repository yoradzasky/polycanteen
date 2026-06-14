<?php

namespace App\Http\Controllers\Api\Student; // Disesuaikan dengan struktur foldermu

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * CartController - Mengelola operasi CRUD untuk keranjang belanja
 */
class CartController extends Controller
{
    /**
     * GET /api/student/cart
     * Retrieve semua item di keranjang untuk mahasiswa yang login
     */
    public function index(Request $request)
    {
        try {
            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            $cartItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->with([
                    'menu' => function ($query) {
                        $query->select('id', 'kantin_id', 'nama_item', 'harga', 'foto_menu', 'deskripsi');
                    },
                    'menu.kantin' => function ($query) {
                        $query->select('id', 'nama_kantin', 'lokasi_lengkap');
                    },
                ])
                ->get();

            // Hitung total dan subtotal untuk setiap item
            $cartItems->each(function ($item) {
                // Pastikan varian berbentuk array atau collection sebelum di-sum
                $varianPrice = collect($item->varian_selected)->sum('harga') ?? 0;
                
                $itemPrice = $item->menu->harga + $varianPrice;
                $item->item_subtotal = $itemPrice * $item->jumlah;
                $item->item_price = $itemPrice;
            });

            return response()->json([
                'success' => true,
                'data' => $cartItems,
                'summary' => [
                    'total_items' => $cartItems->sum('jumlah'),
                    'total_price' => $cartItems->sum('item_subtotal'),
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving cart: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/student/cart
     * Tambah item ke keranjang atau update jumlah jika sudah ada
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'menu_id' => 'required|exists:menu,id',
                'jumlah' => 'required|integer|min:1',
                'varian_selected' => 'nullable|array',
            ]);

            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            // AMBIL SEMUA ITEM KERANJANG DENGAN MENU_ID YANG SAMA
            $existingItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->where('menu_id', $validated['menu_id'])
                ->get();

            $cartItem = null;

            // CEK MANUAL APAKAH ADA ITEM YANG VARIAN-NYA PERSIS SAMA
            foreach ($existingItems as $item) {
                // Membandingkan array secara langsung di PHP
                $isVarianSame = $item->varian_selected == ($validated['varian_selected'] ?? null);

                if ($isVarianSame) {
                    $cartItem = $item;
                    break; // Ditemukan yang persis sama, hentikan pencarian
                }
            }

            if ($cartItem) {
                // Update jumlah JIKA menu dan varian persis sama
                $cartItem->jumlah += $validated['jumlah'];
                $cartItem->save();
                $message = 'Item quantity updated';
            } else {
                // Buat baris baru JIKA menu sama TAPI variannya beda (atau menu benar-benar baru)
                $cartItem = Keranjang::create([
                    'mahasiswa_id' => $mahasiswaId,
                    'menu_id' => $validated['menu_id'],
                    'jumlah' => $validated['jumlah'],
                    'varian_selected' => $validated['varian_selected'] ?? null,
                ]);
                $message = 'Item added to cart';
            }

            $cartItem->load(['menu']);

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => $cartItem,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error adding item: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * PUT /api/student/cart/{id}
     * Update jumlah atau varian dari item keranjang spesifik
     */
    public function update(Request $request, $id)
    {
        try {
            $cartItem = Keranjang::find($id);

            if (!$cartItem) {
                return response()->json(['success' => false, 'message' => 'Cart item not found'], 404);
            }

            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();
            if ($cartItem->mahasiswa_id !== $mahasiswaId) {
                return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
            }

            $validated = $request->validate([
                'jumlah' => 'integer|min:1',
                'varian_selected' => 'nullable|array',
            ]);

            $cartItem->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Cart item updated',
                'data' => $cartItem,
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error updating item: ' . $e->getMessage()], 500);
        }
    }

    /**
     * DELETE /api/student/cart/{menuId}
     * Hapus berdasarkan menu_id (Sesuai aksi tombol Minus di Flutter)
     */
    public function destroy(Request $request, $menuId)
    {
        try {
            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            // Cari item keranjang berdasarkan menu_id milik mahasiswa tersebut
            $cartItem = Keranjang::where('mahasiswa_id', $mahasiswaId)
                                 ->where('menu_id', $menuId)
                                 ->first();

            if (!$cartItem) {
                return response()->json(['success' => false, 'message' => 'Cart item not found'], 404);
            }

            // Logika cerdas: Jika jumlah > 1, kurangi 1. Jika 1, hapus baris data.
            if ($cartItem->jumlah > 1) {
                $cartItem->decrement('jumlah');
                $message = 'Item quantity decreased';
            } else {
                $cartItem->delete();
                $message = 'Item removed from cart';
            }

            return response()->json([
                'success' => true,
                'message' => $message,
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error deleting item: ' . $e->getMessage()], 500);
        }
    }

    /**
     * DELETE /api/student/cart/clear/all
     * Hapus semua item dari keranjang
     */
    public function clearAll()
    {
        try {
            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            Keranjang::where('mahasiswa_id', $mahasiswaId)->delete();

            return response()->json([
                'success' => true,
                'message' => 'Cart cleared',
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error clearing cart: ' . $e->getMessage()], 500);
        }
    }
}