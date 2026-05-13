<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Membuat akun Admin Utama
        User::create([
            'username' => 'Admin Kantin',
            'email' => 'admin@kantin.com',
            'password' => Hash::make('password123'), // Passwordnya: password123
            'role' => 'admin',
            'status_akun' => 'aktif',
        ]);

        // Opsional: Boleh tambah user pembeli juga buat ngetes
        User::create([
            'username' => 'Mahasiswa 1',
            'email' => 'mahasiswa@kantin.com',
            'password' => Hash::make('password123'),
            'role' => 'mahasiswa',
            'status_akun' => 'aktif',
        ]);
    }
}