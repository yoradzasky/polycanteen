<?php

namespace Database\Seeders;

use App\Models\Kantin;
use App\Models\Pegawai;
use App\Models\User;
use Illuminate\Database\Seeder;

class PegawaiSeeder extends Seeder
{
    public function run(): void
    {
        $pegawaiUsers = User::where('role', 'pegawai')->orderBy('id')->get();
        $kantinList   = Kantin::orderBy('id')->get();

        // Distribusi: kantin 1 → 2 pegawai, kantin 2 → 1 pegawai, kantin 3 → 1 pegawai
        $profilPegawai = [
            [
                'nama_karyawan'   => 'Ahmad Fauzi',
                'no_telp'         => '083344556677',
                'foto_profil_path'=> null,
                'kantin_index'    => 0, // Kantin Barokah
            ],
            [
                'nama_karyawan'   => 'Lina Marlina',
                'no_telp'         => '083344556678',
                'foto_profil_path'=> null,
                'kantin_index'    => 0, // Kantin Barokah
            ],
            [
                'nama_karyawan'   => 'Teguh Santoso',
                'no_telp'         => '083344556679',
                'foto_profil_path'=> null,
                'kantin_index'    => 1, // Warung Bu Sri
            ],
            [
                'nama_karyawan'   => 'Rina Oktavia',
                'no_telp'         => '083344556680',
                'foto_profil_path'=> null,
                'kantin_index'    => 2, // Kantin Pak Agus
            ],
        ];

        foreach ($pegawaiUsers as $index => $user) {
            $profil = $profilPegawai[$index];
            Pegawai::create([
                'user_id'         => $user->id,
                'kantin_id'       => $kantinList[$profil['kantin_index']]->id,
                'nama_karyawan'   => $profil['nama_karyawan'],
                'no_telp'         => $profil['no_telp'],
                'foto_profil_path'=> $profil['foto_profil_path'],
            ]);
        }
    }
}
