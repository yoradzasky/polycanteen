<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Menu;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * CartController - Mengelola operasi CRUD untuk keranjang belanja
 * AC 1: Menyediakan fungsi CRUD pada keranjang belanja yang tersinkronisasi via API
 */
class CartController extends Controller
{
    /**
     * GET /api/cart
     * Retrieve semua item di keranjang untuk mahasiswa yang login
     */
    public function index(Request $request)
    {
        try {
            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            $cartItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->with([
                    'menu' => function ($query) {
                        $query->select('id', 'kantin_id', 'nama_menu', 'harga', 'foto_menu', 'deskripsi');
                    },
                    'kantin' => function ($query) {
                        $query->select('id', 'nama_kantin', 'lokasi');
                    },
                ])
                ->get();

            // Hitung total dan subtotal untuk setiap item
            $cartItems->each(function ($item) {
                $varianPrice = collect($item->varian_selected)->sum('harga') ?? 0;
                $toppingPrice = collect($item->topping_selected)->sum('harga') ?? 0;
                $itemPrice = $item->menu->harga + $varianPrice + $toppingPrice;
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
     * POST /api/cart
     * Tambah item ke keranjang atau update jumlah jika sudah ada
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'menu_id' => 'required|exists:menu,id',
                'kantin_id' => 'required|exists:kantin,id',
                'jumlah' => 'required|integer|min:1',
                'varian_selected' => 'nullable|array',
                'topping_selected' => 'nullable|array',
            ]);

            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            // CEK: Apakah item dengan varian yang sama sudah ada di keranjang?
            // Jika ya, update jumlah. Jika tidak, create baru.
            $cartItem = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->where('menu_id', $validated['menu_id'])
                ->where('kantin_id', $validated['kantin_id'])
                ->first();

            if ($cartItem) {
                // Update jumlah jika item sudah ada
                $cartItem->jumlah += $validated['jumlah'];
                $cartItem->save();
                $message = 'Item quantity updated';
            } else {
                // Create item baru ke keranjang
                $cartItem = Keranjang::create([
                    'mahasiswa_id' => $mahasiswaId,
                    'menu_id' => $validated['menu_id'],
                    'kantin_id' => $validated['kantin_id'],
                    'jumlah' => $validated['jumlah'],
                    'varian_selected' => $validated['varian_selected'] ?? null,
                    'topping_selected' => $validated['topping_selected'] ?? null,
                ]);
                $message = 'Item added to cart';
            }

            $cartItem->load(['menu', 'kantin']);

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
     * PUT /api/cart/{id}
     * Update jumlah atau varian dari item keranjang
     */
    public function update(Request $request, $id)
    {
        try {
            $cartItem = Keranjang::find($id);

            if (!$cartItem) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cart item not found',
                ], 404);
            }

            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();
            if ($cartItem->mahasiswa_id !== $mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized',
                ], 403);
            }

            $validated = $request->validate([
                'jumlah' => 'integer|min:1',
                'varian_selected' => 'nullable|array',
                'topping_selected' => 'nullable|array',
            ]);

            $cartItem->update($validated);
            $cartItem->load(['menu', 'kantin']);

            return response()->json([
                'success' => true,
                'message' => 'Cart item updated',
                'data' => $cartItem,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating item: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * DELETE /api/cart/{id}
     * Hapus item dari keranjang
     */
    public function destroy($id)
    {
        try {
            $cartItem = Keranjang::find($id);

            if (!$cartItem) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cart item not found',
                ], 404);
            }

            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();
            if ($cartItem->mahasiswa_id !== $mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized',
                ], 403);
            }

            $cartItem->delete();

            return response()->json([
                'success' => true,
                'message' => 'Item removed from cart',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error deleting item: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * DELETE /api/cart/clear/all
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
            return response()->json([
                'success' => false,
                'message' => 'Error clearing cart: ' . $e->getMessage(),
            ], 500);
        }
    }
}
