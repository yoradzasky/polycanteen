<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use Illuminate\Http\Request;

class MenuController extends Controller
{
    /**
     * Tampil Daftar Menu
     */
    public function index()
    {
        // Ganti baris ini: Hapus where() biar mengambil SEMUA data tanpa terkecuali
        $menus = Menu::all();

        return response()->json([
            'success' => true,
            'message' => 'Daftar semua menu berhasil diambil',
            'data' => $menus
        ]);
    }
}