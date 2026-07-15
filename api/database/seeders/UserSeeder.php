<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // ─── Admin ───────────────────────────────────────────────────────────
        User::create([
            'nama_lengkap'      => 'Admin Polines',
            'email'             => 'admin@polycanteen.id',
            'email_verified_at' => now(),
            'password'          => Hash::make('password'),
            'status_akun'       => 'aktif',
            'role'              => 'admin',
            'foto_profile'      => null,
        ]);

        // ─── Mahasiswa (5 akun) ───────────────────────────────────────────
        $mahasiswaList = [
            ['nama_lengkap' => 'Budi Santoso',    'email' => 'budi@mhs.polines.ac.id'],
            ['nama_lengkap' => 'Siti Rahayu',     'email' => 'siti@mhs.polines.ac.id'],
            ['nama_lengkap' => 'Andi Firmansyah', 'email' => 'andi@mhs.polines.ac.id'],
            ['nama_lengkap' => 'Dewi Lestari',    'email' => 'dewi@mhs.polines.ac.id'],
            ['nama_lengkap' => 'Rizky Pratama',   'email' => 'rizky@mhs.polines.ac.id'],
        ];

        foreach ($mahasiswaList as $mhs) {
            User::create([
                'nama_lengkap'      => $mhs['nama_lengkap'],
                'email'             => $mhs['email'],
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'status_akun'       => 'aktif',
                'role'              => 'mahasiswa',
                'foto_profile'      => null,
            ]);
        }

        // ─── Pemilik Kantin (3 akun) ──────────────────────────────────────
        $pemilikList = [
            ['nama_lengkap' => 'Pak Hendra',  'email' => 'hendra@polycanteen.id'],
            ['nama_lengkap' => 'Bu Sri',      'email' => 'sri@polycanteen.id'],
            ['nama_lengkap' => 'Pak Agus',    'email' => 'agus@polycanteen.id'],
        ];

        foreach ($pemilikList as $pemilik) {
            User::create([
                'nama_lengkap'      => $pemilik['nama_lengkap'],
                'email'             => $pemilik['email'],
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'status_akun'       => 'aktif',
                'role'              => 'pemilik',
                'foto_profile'      => null,
            ]);
        }

        // ─── Pegawai (4 akun) ─────────────────────────────────────────────
        $pegawaiList = [
            ['nama_lengkap' => 'Ahmad Fauzi',    'email' => 'ahmad.fauzi@polycanteen.id'],
            ['nama_lengkap' => 'Lina Marlina',   'email' => 'lina.marlina@polycanteen.id'],
            ['nama_lengkap' => 'Teguh Santoso',  'email' => 'teguh.santoso@polycanteen.id'],
            ['nama_lengkap' => 'Rina Oktavia',   'email' => 'rina.oktavia@polycanteen.id'],
        ];

        foreach ($pegawaiList as $pgw) {
            User::create([
                'nama_lengkap'      => $pgw['nama_lengkap'],
                'email'             => $pgw['email'],
                'email_verified_at' => now(),
                'password'          => Hash::make('password'),
                'status_akun'       => 'aktif',
                'role'              => 'pegawai',
                'foto_profile'      => null,
            ]);
        }
    }
}
