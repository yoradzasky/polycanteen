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
                'nama_mahasiswa'   => 'Budi Santoso',
                'nim'              => '4.33.22.0.01',
                'jurusan'          => 'Teknik Elektro',
                'no_telp'          => '081234567890',
                'masa_aktif'       => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa'   => 'Siti Rahayu',
                'nim'              => '4.33.22.0.02',
                'jurusan'          => 'Teknik Elektro',
                'no_telp'          => '081234567891',
                'masa_aktif'       => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa'   => 'Andi Firmansyah',
                'nim'              => '4.41.22.0.03',
                'jurusan'          => 'Akuntansi',
                'no_telp'          => '081234567892',
                'masa_aktif'       => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa'   => 'Dewi Lestari',
                'nim'              => '4.52.22.0.04',
                'jurusan'          => 'Administrasi Bisnis',
                'no_telp'          => '081234567893',
                'masa_aktif'       => '2026-08-31',
                'foto_profil_path' => null,
            ],
            [
                'nama_mahasiswa'   => 'Rizky Pratama',
                'nim'              => '4.21.22.0.05',
                'jurusan'          => 'Teknik Mesin',
                'no_telp'          => '081234567894',
                'masa_aktif'       => '2026-08-31',
                'foto_profil_path' => null,
            ],
        ];

        foreach ($mahasiswaUsers as $index => $user) {
            if (!isset($profilMahasiswa[$index])) break;
            Mahasiswa::create(array_merge(
                ['user_id' => $user->id],
                $profilMahasiswa[$index]
            ));
        }
    }
}
