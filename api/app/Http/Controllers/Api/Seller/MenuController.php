<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use App\Http\Requests\Seller\StoreMenuRequest;
use App\Http\Requests\Seller\UpdateMenuRequest;
use Illuminate\Auth\Access\AuthorizationException;

class MenuController extends Controller
{
    /**
     * Ambil kantin_id dari relasi Auth::user()->pemilik->kantin_id
     */
    protected function getKantinIdFromAuth()
    {
        $user = Auth::user();
        if ($user->role === 'pemilik' && $user->pemilik) {
            return $user->pemilik->kantin_id;
        } elseif ($user->role === 'pegawai' && $user->pegawai) {
            return $user->pegawai->kantin_id;
        }
        
        return null;
    }

    /**
     * Cek apakah menu->kantin_id == kantin milik user login
     */
    protected function authorizeMenuOwnership(Menu $menu)
    {
        $user = Auth::user();
        
        if (!in_array($user->role, ['pemilik', 'pegawai'])) {
            throw new AuthorizationException('Anda tidak memiliki akses untuk melakukan aksi ini.');
        }

        $kantinId = $this->getKantinIdFromAuth();
        if (!$kantinId || $menu->kantin_id !== $kantinId) {
            throw new AuthorizationException('Anda tidak memiliki akses untuk melakukan aksi ini.');
        }
    }

    /**
     * GET /api/seller/menus
     */
    public function index(Request $request)
    {
        $this->authorize('viewAny', Menu::class);

        $kantinId = $this->getKantinIdFromAuth();

        if (!$kantinId) {
            return response()->json([
                'success' => false,
                'message' => 'Kantin tidak ditemukan untuk user ini.'
            ], 404);
        }

        $query = Menu::where('kantin_id', $kantinId);

        if ($request->has('search') && $request->search != '') {
            $query->where('nama_item', 'like', '%' . $request->search . '%');
        }

        $menus = $query->get();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil data menu',
            'data' => $menus
        ]);
    }

    /**
     * POST /api/seller/menus
     */
    public function store(StoreMenuRequest $request)
    {
        $this->authorize('manage', Menu::class);

        $kantinId = $this->getKantinIdFromAuth();

        if (!$kantinId) {
            return response()->json([
                'success' => false,
                'message' => 'Kantin tidak ditemukan untuk user ini.'
            ], 404);
        }

        $validated = $request->validated();
        
        $validated['kantin_id'] = $kantinId;
        $validated['status_stok'] = true;

        if (isset($validated['varian'])) {
            $validated['varian'] = json_decode($validated['varian'], true);
        }
        
        if (isset($validated['topping'])) {
            $validated['topping'] = json_decode($validated['topping'], true);
        }

        if ($request->hasFile('foto_menu')) {
            $path = $request->file('foto_menu')->store('menus', 'public');
            $validated['foto_menu'] = $path;
        }

        $menu = Menu::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Menu berhasil ditambahkan',
            'data' => $menu
        ], 201);
    }

    /**
     * PUT/PATCH /api/seller/menus/{id}
     */
    public function update(UpdateMenuRequest $request, Menu $menu)
    {
        $this->authorize('manage', Menu::class);
        
        try {
            $this->authorizeMenuOwnership($menu);
        } catch (AuthorizationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 403);
        }

        $validated = $request->validated();

        if (isset($validated['varian'])) {
            $validated['varian'] = json_decode($validated['varian'], true);
        }
        
        if (isset($validated['topping'])) {
            $validated['topping'] = json_decode($validated['topping'], true);
        }

        if ($request->hasFile('foto_menu')) {
            if ($menu->foto_menu && Storage::disk('public')->exists($menu->foto_menu)) {
                Storage::disk('public')->delete($menu->foto_menu);
            }
            $path = $request->file('foto_menu')->store('menus', 'public');
            $validated['foto_menu'] = $path;
        }

        $menu->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Menu berhasil diperbarui',
            'data' => $menu
        ]);
    }

    /**
     * DELETE /api/seller/menus/{id}
     */
    public function destroy(Menu $menu)
    {
        $this->authorize('manage', Menu::class);
        
        try {
            $this->authorizeMenuOwnership($menu);
        } catch (AuthorizationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 403);
        }

        if ($menu->foto_menu && Storage::disk('public')->exists($menu->foto_menu)) {
            Storage::disk('public')->delete($menu->foto_menu);
        }

        $menu->delete();

        return response()->json([
            'success' => true,
            'message' => 'Menu berhasil dihapus'
        ]);
    }

    /**
     * PATCH /api/seller/menus/{id}/toggle-status
     */
    public function toggleStatus(Menu $menu)
    {
        $this->authorize('updateStatus', Menu::class);

        try {
            $this->authorizeMenuOwnership($menu);
        } catch (AuthorizationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 403);
        }

        $menu->status_stok = !$menu->status_stok;
        $menu->save();

        return response()->json([
            'success' => true,
            'message' => 'Status stok berhasil diubah',
            'data' => $menu
        ]);
    }
}
