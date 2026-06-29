<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    /**
     * Helper to generate full URL for a path, handling localhost issues on mobile.
     */
    private function getFullUrl($path)
    {
        if (!$path) return null;
        
        // If it's already a full URL, return it
        if (filter_var($path, FILTER_VALIDATE_URL)) return $path;

        // Use Storage::url to get the relative path (usually starts with /storage)
        $url = Storage::url($path);
        
        // Get the host and trim any trailing slashes
        $host = rtrim(request()->getSchemeAndHttpHost(), '/');
        
        // Ensure $url starts with a slash
        $url = '/' . ltrim($url, '/');
        
        return $host . $url;
    }

    public function show(Request $request)
    {
        $user = $request->user();
        $fotoProfile = $this->getFullUrl($user->foto_profile);
        $nama = $user->courier_name;
        
        if ($user->role === 'pemilik') {
            $pemilik = $user->pemilik;
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $user->id,
                    'username' => $user->username,
                    'email' => $user->email,
                    'role' => $user->role,
                    'nama' => $nama,
                    'nama_pemilik' => $pemilik?->nama_pemilik,
                    'no_telp' => $pemilik?->no_telp,
                    'foto_profil_path' => $fotoProfile, // Use full URL here too
                    'foto_profile' => $fotoProfile,
                ]
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
                'nama' => $nama,
                'foto_profile' => $fotoProfile,
            ]
        ]);
    }

    // Update user profile
    public function update(Request $request)
    {
        $user = $request->user();

        // Accept both spellings: foto_profile (backend convention) and foto_profil (frontend convention)
        $photoField = $request->hasFile('foto_profil') ? 'foto_profil' : 'foto_profile';

        $validated = $request->validate([
            'username' => 'sometimes|string|max:255|unique:users,username,' . $user->id,
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'nama_pemilik' => 'sometimes|string|max:255',
            'no_telp' => 'sometimes|string|max:20',
            $photoField => 'sometimes|image|mimes:jpeg,png,jpg,gif|max:10240',
        ]);

        // Update user data
        if (isset($validated['username'])) {
            $user->username = $validated['username'];
        }
        if (isset($validated['email'])) {
            $user->email = $validated['email'];
        }

        // Handle profile photo upload
        if ($request->hasFile($photoField)) {
            if ($user->foto_profile) {
                Storage::delete('public/' . $user->foto_profile);
            }
            $path = $request->file($photoField)->store('profiles', 'public');
            $user->foto_profile = $path;
        }

        $user->save();

        // Update pemilik data if user is pemilik
        if ($user->role === 'pemilik' && $user->pemilik) {
            $pemilik = $user->pemilik;
            
            if (isset($validated['nama_pemilik'])) {
                $pemilik->nama_pemilik = $validated['nama_pemilik'];
            }
            if (isset($validated['no_telp'])) {
                $pemilik->no_telp = $validated['no_telp'];
            }
            
            // Sync photo path to pemilik table if needed
            if ($request->hasFile($photoField)) {
                $pemilik->foto_profil_path = $user->foto_profile;
            }

            $pemilik->save();
        }

        // Update pegawai data if user is pegawai
        if ($user->role === 'pegawai' && $user->pegawai) {
            $pegawai = $user->pegawai;
            
            if (isset($validated['nama_pemilik'])) {
                $pegawai->nama_karyawan = $validated['nama_pemilik'];
            }
            if (isset($validated['no_telp'])) {
                $pegawai->no_telp = $validated['no_telp'];
            }
            
            if ($request->hasFile($photoField)) {
                $pegawai->foto_profil_path = $user->foto_profile;
            }

            $pegawai->save();
        }

        $fotoProfileUrl = $this->getFullUrl($user->foto_profile);

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui',
            'data' => [
                'id' => $user->id,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
                'nama' => $user->courier_name,
                'foto_profile' => $fotoProfileUrl,
                'nama_pemilik' => $user->pemilik?->nama_pemilik,
                'no_telp' => $user->pemilik?->no_telp ?? $user->pegawai?->no_telp,
            ]
        ]);
    }

    
    // Get kantin profile
    public function getKantinProfile(Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== 'pemilik') {
            return response()->json([
                'success' => false,
                'message' => 'User bukan pemilik kantin'
            ], 403);
        }

        $kantin = $user->pemilik?->kantin;
        
        if (!$kantin) {
            return response()->json([
                'success' => false,
                'message' => 'Kantin tidak ditemukan'
            ], 404);
        }

        $fotoKantin = $this->getFullUrl($kantin->logo_path);

        // Menghitung rata-rata rating dari tabel ulasan
        $rataRataRating = \App\Models\Ulasan::where('kantin_id', $kantin->id)->avg('rating');
        $ratingFinal = $rataRataRating ? round($rataRataRating, 1) : 0.0;

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $kantin->id,
                'nama_kantin' => $kantin->nama_kantin,
                'deskripsi' => $kantin->deskripsi ?? '',
                'alamat' => $kantin->alamat ?? '',
                'foto_kantin' => $fotoKantin,
                'rating' => $ratingFinal,
                'total_pesanan' => $kantin->total_pesanan ?? 0,
            ]
        ]);
    }

    // Update kantin profile
    public function updateKantinProfile(Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== 'pemilik') {
            return response()->json([
                'success' => false,
                'message' => 'User bukan pemilik kantin'
            ], 403);
        }

        $kantin = $user->pemilik?->kantin;
        
        if (!$kantin) {
            return response()->json([
                'success' => false,
                'message' => 'Kantin tidak ditemukan'
            ], 404);
        }

        $validated = $request->validate([
            'nama_kantin' => 'sometimes|string|max:255',
            'deskripsi' => 'sometimes|string|max:1000',
            'alamat' => 'sometimes|string|max:500',
            'foto_kantin' => 'sometimes|image|mimes:jpeg,png,jpg,gif|max:10240',
        ]);

        if (isset($validated['nama_kantin'])) {
            $kantin->nama_kantin = $validated['nama_kantin'];
        }
        if (isset($validated['deskripsi'])) {
            $kantin->deskripsi = $validated['deskripsi'];
        }
        if (isset($validated['alamat'])) {
            $kantin->alamat = $validated['alamat'];
        }

        // Handle kantin photo upload
        if ($request->hasFile('foto_kantin')) {
            if ($kantin->logo_path) {
                Storage::delete('public/' . $kantin->logo_path);
            }
            $path = $request->file('foto_kantin')->store('kantin', 'public');
            $kantin->logo_path = $path;
        }

        $kantin->save();

        $fotoKantinUrl = $this->getFullUrl($kantin->logo_path);

        return response()->json([
            'success' => true,
            'message' => 'Profil kantin berhasil diperbarui',
            'data' => [
                'id' => $kantin->id,
                'nama_kantin' => $kantin->nama_kantin,
                'deskripsi' => $kantin->deskripsi,
                'alamat' => $kantin->alamat,
                'foto_kantin' => $fotoKantinUrl,
            ]
        ]);
    }

    // Change password
    public function changePassword(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        // Check current password
        if (!\Illuminate\Support\Facades\Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password saat ini tidak sesuai'
            ], 401);
        }

        // Update password
        $user->password = $validated['new_password'];
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah'
        ]);
    }
}
