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
            'username'          => 'admin',
            'email'             => 'admin@polycanteen.id',
            'email_verified_at' => now(),
            'password'          => Hash::make('password'),
            'status_akun'       => 'aktif',
            'role'              => 'admin',
            'foto_profile'      => null,
        ]);

        // ─── Mahasiswa (5 akun) ───────────────────────────────────────────
        $mahasiswaList = [
            ['username' => 'budi_santoso',   'email' => 'budi@student.politeknik.ac.id'],
            ['username' => 'siti_rahayu',    'email' => 'siti@student.politeknik.ac.id'],
            ['username' => 'andi_firmansyah','email' => 'andi@student.politeknik.ac.id'],
            ['username' => 'dewi_lestari',   'email' => 'dewi@student.politeknik.ac.id'],
            ['username' => 'rizky_pratama',  'email' => 'rizky@student.politeknik.ac.id'],
        ];

        foreach ($mahasiswaList as $mhs) {
            User::create([
                'username'          => $mhs['username'],
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
            ['username' => 'pak_hendra',  'email' => 'hendra@polycanteen.id'],
            ['username' => 'bu_sri',      'email' => 'sri@polycanteen.id'],
            ['username' => 'pak_agus',    'email' => 'agus@polycanteen.id'],
        ];

        foreach ($pemilikList as $pemilik) {
            User::create([
                'username'          => $pemilik['username'],
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
            ['username' => 'pegawai_kantin1_a', 'email' => 'pgw1a@polycanteen.id'],
            ['username' => 'pegawai_kantin1_b', 'email' => 'pgw1b@polycanteen.id'],
            ['username' => 'pegawai_kantin2_a', 'email' => 'pgw2a@polycanteen.id'],
            ['username' => 'pegawai_kantin3_a', 'email' => 'pgw3a@polycanteen.id'],
        ];

        foreach ($pegawaiList as $pgw) {
            User::create([
                'username'          => $pgw['username'],
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
