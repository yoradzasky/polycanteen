<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class MahasiswaController extends Controller
{
    /**
     * Mengambil semua data yang dibutuhkan untuk halaman beranda mahasiswa.
     */
    public function getBerandaData(Request $request)
    {
        // Ambil data user yang sedang login via Sanctum
        $user = $request->user();
        
        // Kriteria 1: Ambil data dari tabel mahasiswa berdasarkan user_id
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data mahasiswa tidak ditemukan.'
            ], 404);
        }

        // Kriteria 2: Ambil pesanan aktif (status: dibayar, dimasak, dalam_perjalanan)
        // DITAMBAHKAN: Status 'selesai' juga ikut diambil TAPI dibatasi hanya yang maksimal 2 jam terakhir
        $pesananAktif = Pesanan::with(['details.menu'])
            ->where('mahasiswa_id', $mahasiswa->id)
            ->where(function ($query) {
                // Tampilkan yang sedang berproses
                $query->whereIn('status_pesanan', ['dibayar', 'dimasak', 'dalam_perjalanan'])
                      ->orWhere(function ($q) {
                          // Tampilkan yang sudah selesai, batasi maksimal 2 jam terakhir
                          $q->where('status_pesanan', 'selesai')
                            ->where('updated_at', '>=', now()->subHours(2));
                      });
            })
            ->latest() // Ambil pesanan terbaru jika ada lebih dari satu
            ->first();

        // Kriteria 4: Pesan Ulang Cepat
        // Ambil riwayat transaksi yang memiliki status_pesanan 'selesai'
        $pesanUlang = Pesanan::with(['details.menu', 'kantin'])
            ->where('mahasiswa_id', $mahasiswa->id)
            ->where('status_pesanan', 'selesai')
            ->latest()
            ->take(5) // Batasi maksimal 5 riwayat terbaru untuk performa list horizontal
            ->get();

        // Kriteria 5 & 7: Menu Ekspres
        // Menampilkan menu dari semua kantin yang estimasi_waktu kurang dari 5 menit
        $menuEkspres = Menu::with('kantin')
            ->where('estimasi_waktu', '<', 5)
            ->where('status_stok', true) // Pastikan stoknya tersedia
            ->withAvg('ulasan', 'rating')
            ->withCount('ulasan')
            ->get();

        // Kriteria 7: Semua Menu
        // Menampilkan seluruh katalog menu beserta data relasi kantinnya
        $semuaMenu = Menu::with('kantin')
        ->where('status_stok', true) // Hanya ambil yang tersedia
        ->withAvg('ulasan', 'rating')
        ->withCount('ulasan')
        ->get();

        // Mengembalikan response JSON dengan struktur key yang match dengan model/state di Flutter
        return response()->json([
            'status' => 'success',
            'user' => [
                'nama_mahasiswa' => $mahasiswa->nama_mahasiswa,
                'foto_profil_path' => $mahasiswa->foto_profil_path,
            ],
            'pesanan_aktif' => $pesananAktif,
            'pesan_ulang' => $pesanUlang,
            'menu_ekspres' => $menuEkspres,
            'semua_menu' => $semuaMenu
        ], 200);
    }

    /**
     * Mengambil data profil lengkap mahasiswa untuk ProfileScreen.
     */
    public function getProfileData(Request $request)
    {
        $user = $request->user();
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return response()->json([
                'status' => 'error',
                'message' => 'Profil tidak ditemukan.'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'nama_mahasiswa'   => $mahasiswa->nama_mahasiswa,
                'nim'              => $mahasiswa->nim,
                'jurusan'          => $mahasiswa->jurusan,
                'no_telp'          => $mahasiswa->no_telp,
                'email'            => $user->email,
                'foto_profil_path' => $mahasiswa->foto_profil_path,
            ]
        ], 200);
    }

    /**
     * Mengupdate profil mahasiswa (nama, nim, no_telp, dan foto).
     */
    public function updateProfile(Request $request)
    {
        // 1. Validasi input dengan custom message Bahasa Indonesia
        $request->validate([
            'nama_mahasiswa' => 'required|string|max:255',
            'nim'            => 'required|string|max:20',
            'jurusan'        => 'nullable|string|max:100',
            'no_telp'        => 'required|string|max:30',
            'email'          => 'required|email|unique:users,email,' . $request->user()->id,
            'foto_profile'   => 'nullable|image|mimes:jpeg,png,jpg|max:3072', // Maks 3MB
        ], [
            // --- DAFTAR ALASAN SPESIFIK BAHASA INDONESIA ---
            'nama_mahasiswa.required' => 'Nama mahasiswa tidak boleh kosong.',
            'nim.required'            => 'NIM tidak boleh kosong.',
            'no_telp.required'        => 'Nomor telepon tidak boleh kosong.',
            'no_telp.max'             => 'Nomor telepon tidak boleh lebih dari 30 karakter.',
            'email.required'          => 'Email tidak boleh kosong.',
            'email.email'             => 'Format email tidak valid.',
            'email.unique'            => 'Email ini sudah terdaftar di akun lain.',
            'foto_profile.image'      => 'File yang diupload harus berupa gambar.',
            'foto_profile.mimes'      => 'Format foto harus berupa JPG, JPEG, atau PNG.',
            'foto_profile.max'        => 'Ukuran foto terlalu besar, maksimal 3MB.',
        ]);

        $user = $request->user();
        $mahasiswa = $user->mahasiswa;

        if (!$mahasiswa) {
            return response()->json(['message' => 'Data mahasiswa tidak ditemukan.'], 404);
        }

        // 2. Gunakan DB Transaction agar data di tabel users & mahasiswa sinkron
        DB::transaction(function () use ($request, $user, $mahasiswa) {
            // Update email di tabel users
            $user->update(['email' => $request->email]);

            // Update data di tabel mahasiswa
            $mahasiswa->nama_mahasiswa = $request->nama_mahasiswa;
            $mahasiswa->nim = $request->nim;
            $mahasiswa->jurusan = $request->jurusan;
            $mahasiswa->no_telp = $request->no_telp;

            // Handle Update Foto Profil jika ada file baru
            if ($request->hasFile('foto_profile')) {
                // Hapus foto lama jika ada
                if ($mahasiswa->foto_profil_path) {
                    Storage::disk('public')->delete($mahasiswa->foto_profil_path);
                }
                // Simpan foto baru ke folder 'profiles' di public storage
                $path = $request->file('foto_profile')->store('profiles', 'public');
                $mahasiswa->foto_profil_path = $path;
            }

            $mahasiswa->save();
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Profil berhasil diperbarui.'
        ], 200);
    }
}