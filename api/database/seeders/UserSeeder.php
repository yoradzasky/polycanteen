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
            'nama_lengkap'      => 'admin',
            'email'             => 'admin@polycanteen.id',
            'email_verified_at' => now(),
            'password'          => Hash::make('password'),
            'status_akun'       => 'aktif',
            'role'              => 'admin',
            'foto_profile'      => null,
        ]);

        // ─── Mahasiswa (5 akun) ───────────────────────────────────────────
        $mahasiswaList = [
            ['nama_lengkap' => 'budi_santoso',   'email' => 'budi@student.politeknik.ac.id'],
            ['nama_lengkap' => 'siti_rahayu',    'email' => 'siti@student.politeknik.ac.id'],
            ['nama_lengkap' => 'andi_firmansyah','email' => 'andi@student.politeknik.ac.id'],
            ['nama_lengkap' => 'dewi_lestari',   'email' => 'dewi@student.politeknik.ac.id'],
            ['nama_lengkap' => 'rizky_pratama',  'email' => 'rizky@student.politeknik.ac.id'],
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
            ['nama_lengkap' => 'pak_hendra',  'email' => 'hendra@polycanteen.id'],
            ['nama_lengkap' => 'bu_sri',      'email' => 'sri@polycanteen.id'],
            ['nama_lengkap' => 'pak_agus',    'email' => 'agus@polycanteen.id'],
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
            ['nama_lengkap' => 'pegawai_kantin1_a', 'email' => 'pgw1a@polycanteen.id'],
            ['nama_lengkap' => 'pegawai_kantin1_b', 'email' => 'pgw1b@polycanteen.id'],
            ['nama_lengkap' => 'pegawai_kantin2_a', 'email' => 'pgw2a@polycanteen.id'],
            ['nama_lengkap' => 'pegawai_kantin3_a', 'email' => 'pgw3a@polycanteen.id'],
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
