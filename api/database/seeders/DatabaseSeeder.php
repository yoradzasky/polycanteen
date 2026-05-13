<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Mahasiswa; // Wajib dipanggil
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon; // Wajib dipanggil untuk mengatur waktu

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Membuat akun Admin Utama
        User::create([
            'username' => 'Admin Kantin',
            'email' => 'admin@kantin.com',
            'password' => Hash::make('password123'), 
            'role' => 'admin',
            'status_akun' => 'aktif',
        ]);

        // 2. Membuat akun User Mahasiswa
        $akunMahasiswa = User::create([
            'username' => 'Mahasiswa 1',
            'email' => 'mahasiswa@kantin.com',
            'password' => Hash::make('password123'),
            'role' => 'mahasiswa',
            'status_akun' => 'aktif',
        ]);

        // 3. Membuat Profil Mahasiswa (Ini kunci agar statusnya "Aktif")
        Mahasiswa::create([
            'user_id' => $akunMahasiswa->id,
            'nama_mahasiswa' => 'Mahasiswa 1', // Menggunakan nama Mahasiswa 1
            'nim' => '3.34.21.0.01',
            'no_telp' => '081234567890',
            'masa_aktif' => Carbon::now()->addDays(30), // Set masa aktif 30 hari ke depan
        ]);
    }
}