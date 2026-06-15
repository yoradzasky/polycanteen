<?php

namespace Database\Seeders;

use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Database\Seeder;

class MahasiswaSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil user dengan role mahasiswa (sesuai urutan insert di UserSeeder)
        $mahasiswaUsers = User::where('role', 'mahasiswa')->orderBy('id')->get();

        $profilMahasiswa = [
            [
                'nama_mahasiswa' => 'Budi Santoso',
                'nim'            => '22410100001',
                'no_telp'        => '081234567890',
                'masa_aktif'     => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa' => 'Siti Rahayu',
                'nim'            => '22410100002',
                'no_telp'        => '081234567891',
                'masa_aktif'     => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa' => 'Andi Firmansyah',
                'nim'            => '22410100003',
                'no_telp'        => '081234567892',
                'masa_aktif'     => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa' => 'Dewi Lestari',
                'nim'            => '22410100004',
                'no_telp'        => '081234567893',
                'masa_aktif'     => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa' => 'Rizky Pratama',
                'nim'            => '22410100005',
                'no_telp'        => '081234567894',
                'masa_aktif'     => '2026-08-31',
                'foto_profil_path' => null,
            ],
        ];

        foreach ($mahasiswaUsers as $index => $user) {
            Mahasiswa::create(array_merge(
                ['user_id' => $user->id],
                $profilMahasiswa[$index]
            ));
        }
    }
}
