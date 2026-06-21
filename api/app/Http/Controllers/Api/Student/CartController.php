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
            $mahasiswaId = Auth::guard('sanctum')->user()->mahasiswa?->id ?? Auth::user()->mahasiswa?->id;
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

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
                $varianPrice = 0;
                
                if (is_array($item->varian_selected)) {
                    foreach ($item->varian_selected as $key => $value) {
                        // Jika Wajib (Associative Array dengan key 'harga')
                        if (is_array($value) && isset($value['harga'])) {
                            $varianPrice += $value['harga'];
                        } 
                        // Jika Opsional (Array dari Associative Arrays)
                        elseif (is_array($value)) {
                            foreach ($value as $v) {
                                if (is_array($v) && isset($v['harga'])) {
                                    $varianPrice += $v['harga'];
                                }
                            }
                        }
                    }
                }
                
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

            $mahasiswaId = Auth::guard('sanctum')->user()->mahasiswa?->id ?? Auth::user()->mahasiswa?->id;
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            // AMBIL SEMUA ITEM KERANJANG DENGAN MENU_ID YANG SAMA
            $existingItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->where('menu_id', $validated['menu_id'])
                ->get();

            $cartItem = null;

            // CEK MANUAL APAKAH ADA ITEM YANG VARIAN-NYA PERSIS SAMA
            foreach ($existingItems as $item) {
                // Gunakan helper khusus agar aman meski urutan key/value JSON berantakan
                $isVarianSame = $this->isVarianEqual($item->varian_selected, $validated['varian_selected'] ?? null);

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

            $mahasiswaId = Auth::guard('sanctum')->user()->mahasiswa?->id ?? Auth::user()->mahasiswa?->id;
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
     * Hapus berdasarkan menu_id
     */
    public function destroy(Request $request, $menuId)
    {
        try {
            $mahasiswaId = Auth::guard('sanctum')->user()->mahasiswa?->id ?? Auth::user()->mahasiswa?->id;
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            // Ambil SEMUA data keranjang untuk menu_id ini
            $cartItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                                  ->where('menu_id', $menuId)
                                  ->get();

            if ($cartItems->isEmpty()) {
                return response()->json(['success' => false, 'message' => 'Cart item not found'], 404);
            }

            // CEK LOGIKA: Jika ada lebih dari 1 baris (artinya ada > 1 varian untuk menu ini)
            if ($cartItems->count() > 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Menu ini memiliki beberapa varian di keranjang. Silakan kurangi di Halaman Keranjang.'
                ], 400); // Kembalikan error 400 Bad Request
            }

            // Jika hanya ada 1 baris, aman untuk dikurangi
            $cartItem = $cartItems->first();

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
            $mahasiswaId = Auth::guard('sanctum')->user()->mahasiswa?->id ?? Auth::user()->mahasiswa?->id;
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            Keranjang::where('mahasiswa_id', $mahasiswaId)->delete();

            return response()->json([
                'success' => true,
                'message' => 'Cart cleared',
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error clearing cart: ' . $e->getMessage()], 500);
        }
    }

    /**
     * POST /api/student/cart/checkout
     * Checkout items in the cart to create a new Pesanan
     */
    public function checkout(Request $request)
    {
        try {
            $user = Auth::guard('sanctum')->user() ?? Auth::user();
            $mahasiswaId = $user->mahasiswa?->id;
            if (!$mahasiswaId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Anda tidak terdaftar sebagai mahasiswa.',
                ], 403);
            }

            // Get cart items
            $cartItems = Keranjang::where('mahasiswa_id', $mahasiswaId)->with('menu')->get();

            if ($cartItems->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Keranjang kosong.',
                ], 400);
            }

            // Calculate totals and extract kantin_id
            $totalHarga = 0;
            $kantinId = null;

            foreach ($cartItems as $item) {
                if (!$kantinId) {
                    $kantinId = $item->menu->kantin_id;
                }

                $varianPrice = 0;
                if (is_array($item->varian_selected)) {
                    foreach ($item->varian_selected as $key => $value) {
                        if (is_array($value) && isset($value['harga'])) {
                            $varianPrice += $value['harga'];
                        } elseif (is_array($value)) {
                            foreach ($value as $v) {
                                if (is_array($v) && isset($v['harga'])) {
                                    $varianPrice += $v['harga'];
                                }
                            }
                        }
                    }
                }

                $itemPrice = $item->menu->harga + $varianPrice;
                $totalHarga += $itemPrice * $item->jumlah;
            }

            // Begin database transaction
            \Illuminate\Support\Facades\DB::beginTransaction();

            // Create Pesanan
            $pesanan = \App\Models\Pesanan::create([
                'mahasiswa_id' => $mahasiswaId,
                'kantin_id' => $kantinId,
                'tipe_pesanan' => 'dine-in', // Default
                'status_pesanan' => 'pending',
                'total_harga' => $totalHarga,
                'nomor_antrian' => null,
                'catatan_pesanan' => $request->input('catatan_pesanan'),
            ]);

            // Create PesananDetail and delete cart items
            foreach ($cartItems as $item) {
                $varianPrice = 0;
                if (is_array($item->varian_selected)) {
                    foreach ($item->varian_selected as $key => $value) {
                        if (is_array($value) && isset($value['harga'])) {
                            $varianPrice += $value['harga'];
                        } elseif (is_array($value)) {
                            foreach ($value as $v) {
                                if (is_array($v) && isset($v['harga'])) {
                                    $varianPrice += $v['harga'];
                                }
                            }
                        }
                    }
                }

                $itemPrice = $item->menu->harga + $varianPrice;

                \App\Models\PesananDetail::create([
                    'pesanan_id' => $pesanan->id,
                    'menu_id' => $item->menu_id,
                    'harga_saat_beli' => $itemPrice,
                    'jumlah_pesanan' => $item->jumlah,
                    'subtotal' => $itemPrice * $item->jumlah,
                    'varian_snapshot' => $item->varian_selected,
                ]);
            }

            // Create default Payment record
            \App\Models\Payment::create([
                'pesanan_id' => $pesanan->id,
                'metode_bayar' => 'qris',
                'status_bayar' => 'pending',
                'log_transaksi' => 'Pesanan dibuat, menunggu pembayaran',
                'nominal' => $totalHarga,
                'midtrans_order_id' => 'ORDER-' . strtoupper(\Illuminate\Support\Str::random(8)),
            ]);

            // Clear Cart
            Keranjang::where('mahasiswa_id', $mahasiswaId)->delete();

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Checkout berhasil.',
                'data' => [
                    'id' => $pesanan->id,
                    'total_harga' => $pesanan->total_harga,
                ]
            ], 201);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Checkout gagal: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Membandingkan dua array varian secara akurat tanpa peduli urutan elemennya
     */
    private function isVarianEqual($varian1, $varian2)
    {
        if (is_null($varian1) && is_null($varian2)) return true;
        if (is_null($varian1) || is_null($varian2)) return false;

        // Pastikan keduanya berbentuk array murni
        $v1 = json_decode(json_encode($varian1), true);
        $v2 = json_decode(json_encode($varian2), true);

        // Sortir sampai ke akar (nested arrays)
        $this->recursiveSort($v1);
        $this->recursiveSort($v2);

        return json_encode($v1) === json_encode($v2);
    }

    /**
     * Fungsi rekursif untuk menyortir array
     */
    private function recursiveSort(&$array)
    {
        if (!is_array($array)) return;

        // Cek apakah array ini asosiatif (punya key string) atau sequential (index angka)
        $isAssoc = array_keys($array) !== range(0, count($array) - 1);

        if ($isAssoc) {
            ksort($array); // Urutkan berdasarkan Key (Misal: "Ekstra", "Porsi")
        } else {
            sort($array);  // Urutkan berdasarkan Value (Misal List topping: "Keju", "Sosis")
        }

        // Jalankan fungsi ini ke array di dalamnya
        foreach ($array as &$value) {
            if (is_array($value)) {
                $this->recursiveSort($value);
            }
        }
    }
}