<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Kantin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class KantinController extends Controller
{
    public function updateStatus(Request $request)
    {
        $request->validate(['status_toko' => 'required|in:buka,tutup']);
        
        $user = Auth::user();
        // Menggunakan relasi yang sudah ada di model User/Pegawai
        $kantinId = $user->pegawai ? $user->pegawai->kantin_id : ($user->pemilik ? $user->pemilik->kantin_id : null);

        if (!$kantinId) {
            return response()->json(['success' => false, 'message' => 'Kantin tidak ditemukan'], 404);
        }

        $kantin = Kantin::find($kantinId);
        $kantin->status_toko = $request->status_toko;
        $kantin->save();

        return response()->json(['success' => true, 'message' => 'Status toko berhasil diubah']);
    }
}