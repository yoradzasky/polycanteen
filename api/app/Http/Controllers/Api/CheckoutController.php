<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Keranjang;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

/**
 * CheckoutController - Mengelola proses checkout dari keranjang ke pesanan
 * AC 2: Fungsi Checkout dapat mengonversi seluruh isi keranjang menjadi data pada tabel `pesanan` dan `pesanan_detail`.
 * AC 3: Sistem mutlak harus menyimpan snapshot harga dan varian pada `pesanan_detail` agar riwayat transaksi tetap konsisten
 */
class CheckoutController extends Controller
{
    /**
     * POST /api/checkout
     * Proses checkout: konversi keranjang menjadi pesanan dengan snapshot harga
     * 
     * CRITICAL LOGIC:
     * 1. Ambil semua item dari keranjang
     * 2. Untuk setiap item, hitung dan SIMPAN snapshot harga saat itu
     * 3. Create record di tabel `pesanan` (header transaksi)
     * 4. Create record di tabel `pesanan_detail` dengan snapshot harga & varian (line items)
     * 5. Kosongkan keranjang setelah checkout berhasil
     */
    public function checkout(Request $request)
    {
        $validated = $request->validate([
            'kantin_id' => 'required|exists:kantin,id',
            'tipe_pesanan' => 'required|in:dine_in,takeaway,delivery',
            'catatan_pesanan' => 'nullable|string|max:500',
            'alamat_pengiriman' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

        // START TRANSACTION untuk memastikan konsistensi data
        DB::beginTransaction();

        try {
            // STEP 1: Ambil semua item keranjang untuk kantin ini
            $cartItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->where('kantin_id', $validated['kantin_id'])
                ->with('menu')
                ->get();

            if ($cartItems->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cart is empty',
                ], 400);
            }

            // STEP 2: Hitung total harga dengan snapshot
            $totalHarga = 0;
            $pesananDetails = [];

            foreach ($cartItems as $item) {
                // ===== SNAPSHOT HARGA CALCULATION =====
                // Harga menu saat ini (untuk snapshot)
                $hargaMenu = $item->menu->harga;

                // Jika ada varian, tambahkan harga variannya
                $varianSnapshot = $item->varian_selected ?? [];
                $varianPrice = 0;
                if (!empty($varianSnapshot)) {
                    $varianPrice = collect($varianSnapshot)->sum('harga') ?? 0;
                }

                // Jika ada topping, tambahkan harga toppingnya
                $toppingSnapshot = $item->topping_selected ?? [];
                $toppingPrice = 0;
                if (!empty($toppingSnapshot)) {
                    $toppingPrice = collect($toppingSnapshot)->sum('harga') ?? 0;
                }

                // TOTAL HARGA PER ITEM = (harga menu + varian + topping) * jumlah
                $hargaSaatBeli = $hargaMenu + $varianPrice + $toppingPrice;
                $subtotal = $hargaSaatBeli * $item->jumlah;

                $totalHarga += $subtotal;

                // Siapkan data untuk pesanan_detail
                $pesananDetails[] = [
                    'menu_id' => $item->menu_id,
                    'harga_saat_beli' => $hargaSaatBeli,
                    'jumlah_pesanan' => $item->jumlah,
                    'subtotal' => $subtotal,
                    // SNAPSHOT: Simpan varian dan topping apa saja yang dipilih saat ini
                    // Jika harga menu berubah nanti, data ini tetap sama untuk riwayat
                    'varian_snapshot' => json_encode($varianSnapshot),
                    'topping_snapshot' => json_encode($toppingSnapshot),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // STEP 3: Hitung biaya layanan jika delivery
            $biayaLayanan = 0;
            if ($validated['tipe_pesanan'] === 'delivery') {
                $biayaLayanan = 5000; // Bisa dari config atau parameter
            }

            // STEP 4: Create Pesanan (header transaksi)
            $pesanan = Pesanan::create([
                'mahasiswa_id' => $mahasiswaId,
                'kantin_id' => $validated['kantin_id'],
                'tipe_pesanan' => $validated['tipe_pesanan'],
                'status_pesanan' => 'pending', // Awalnya pending, tunggu pembayaran
                'total_harga' => $totalHarga + $biayaLayanan,
                'biaya_layanan' => $biayaLayanan,
                'catatan_pesanan' => $validated['catatan_pesanan'] ?? null,
                'alamat_pengiriman' => $validated['alamat_pengiriman'] ?? null,
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
            ]);

            // STEP 5: Create PesananDetail untuk setiap item
            foreach ($pesananDetails as &$detail) {
                $detail['pesanan_id'] = $pesanan->id;
            }

            PesananDetail::insert($pesananDetails);

            // STEP 6: Kosongkan keranjang untuk kantin ini
            Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->where('kantin_id', $validated['kantin_id'])
                ->delete();

            // COMMIT TRANSACTION
            DB::commit();

            // Load relasi untuk response
            $pesanan->load(['details', 'mahasiswa', 'kantin']);

            return response()->json([
                'success' => true,
                'message' => 'Checkout successful',
                'data' => [
                    'pesanan_id' => $pesanan->id,
                    'pesanan' => $pesanan,
                    'subtotal' => $totalHarga,
                    'biaya_layanan' => $biayaLayanan,
                    'total' => $totalHarga + $biayaLayanan,
                ],
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error during checkout: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/checkout/preview
     * Preview biaya sebelum checkout (untuk validasi di UI)
     */
    public function preview(Request $request)
    {
        try {
            $validated = $request->validate([
                'kantin_id' => 'required|exists:kantin,id',
                'tipe_pesanan' => 'required|in:dine_in,takeaway,delivery',
            ]);

            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            $cartItems = Keranjang::where('mahasiswa_id', $mahasiswaId)
                ->where('kantin_id', $validated['kantin_id'])
                ->with('menu')
                ->get();

            if ($cartItems->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cart is empty',
                ], 400);
            }

            $subtotal = 0;
            $itemDetails = [];

            foreach ($cartItems as $item) {
                $varianPrice = collect($item->varian_selected)->sum('harga') ?? 0;
                $toppingPrice = collect($item->topping_selected)->sum('harga') ?? 0;
                $itemPrice = $item->menu->harga + $varianPrice + $toppingPrice;
                $itemSubtotal = $itemPrice * $item->jumlah;

                $subtotal += $itemSubtotal;

                $itemDetails[] = [
                    'menu_id' => $item->menu_id,
                    'menu_name' => $item->menu->nama_menu,
                    'price' => $itemPrice,
                    'quantity' => $item->jumlah,
                    'subtotal' => $itemSubtotal,
                ];
            }

            $biayaLayanan = 0;
            if ($validated['tipe_pesanan'] === 'delivery') {
                $biayaLayanan = 5000;
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'items' => $itemDetails,
                    'subtotal' => $subtotal,
                    'biaya_layanan' => $biayaLayanan,
                    'total' => $subtotal + $biayaLayanan,
                    'tipe_pesanan' => $validated['tipe_pesanan'],
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error generating preview: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/pesanan/{id}
     * Lihat detail pesanan yang sudah checkout
     */
    public function getOrder($id)
    {
        try {
            $mahasiswaId = Auth::guard('sanctum')->user()->id ?? Auth::id();

            $pesanan = Pesanan::where('id', $id)
                ->where('mahasiswa_id', $mahasiswaId)
                ->with(['details', 'mahasiswa', 'kantin', 'payment'])
                ->first();

            if (!$pesanan) {
                return response()->json([
                    'success' => false,
                    'message' => 'Order not found',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $pesanan,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error retrieving order: ' . $e->getMessage(),
            ], 500);
        }
    }
}
