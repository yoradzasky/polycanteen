<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Login API
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // Cari user berdasarkan email
        $user = User::where('email', $request->email)->first();

        // Cek apakah user ada dan passwordnya benar
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau Password salah.'
            ], 401); // 401 = Unauthorized
        }

        // Cek apakah akun nonaktif
        if ($user->status_akun === 'nonaktif') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda sedang dinonaktifkan. Silakan hubungi admin.'
            ], 403);
        }

        // Hapus token lama agar tidak menumpuk (Opsional)
        $user->tokens()->delete();

        // Buat token baru
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                'user' => $user,
                'token' => $token 
            ]
        ]);
    }
    /**
     * Logout API
     */
    public function logout(Request $request)
    {
        $user = $request->user();

        // Hapus FCM token dari database agar tidak menerima notifikasi lagi setelah logout
        if ($user) {
            $user->update(['fcm_token' => null]);
            $user->currentAccessToken()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil, token telah dihapus'
        ]);
    }

    /**
     * Register API (Submit BuyerApplication)
     */
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:buyer_applications,email|unique:users,email',
            'nim' => 'required|string|unique:buyer_applications,nim|unique:mahasiswa,nim',
            'jurusan' => 'nullable|string|max:100',
            'phone' => 'required|string|max:20',
            'password' => 'required|string|min:6',
            'foto_ktm' => 'nullable|image|max:2048', // Max 2MB
        ]);

        $fotoKtmPath = null;
        if ($request->hasFile('foto_ktm')) {
            $fotoKtmPath = $request->file('foto_ktm')->store('ktm', 'public');
        }

        $application = \App\Models\BuyerApplication::create([
            'name' => $request->name,
            'email' => $request->email,
            'nim' => $request->nim,
            'jurusan' => $request->jurusan,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'foto_ktm_path' => $fotoKtmPath,
            'status' => 'pending',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pendaftaran berhasil diajukan. Silakan tunggu persetujuan admin.',
            'data' => $application
        ], 201);
    }
}  