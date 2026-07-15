<?php

namespace Database\Seeders;

use App\Models\Kantin;
use App\Models\Pemilik;
use App\Models\User;
use Illuminate\Database\Seeder;

class PemilikSeeder extends Seeder
{
    public function run(): void
    {
        $pemilikUsers = User::where('role', 'pemilik')->orderBy('id')->get();
        $kantinList   = Kantin::orderBy('id')->get();

        $profilPemilik = [
            [
                'nama_pemilik'    => 'Hendra Wijaya',
                'no_telp'         => '082111222333',
                'foto_profil_path'=> null,
            ],
            [
                'nama_pemilik'    => 'Sri Wahyuni',
                'no_telp'         => '082111222334',
                'foto_profil_path'=> null,
            ],
            [
                'nama_pemilik'    => 'Agus Mulyono',
                'no_telp'         => '082111222335',
                'foto_profil_path'=> null,
            ],
        ];

        // Setiap pemilik memiliki 1 kantin (1-to-1 sesuai urutan)
        foreach ($pemilikUsers as $index => $user) {
            Pemilik::create([
                'user_id'         => $user->id,
                'kantin_id'       => $kantinList[$index]->id,
                'nama_pemilik'    => $profilPemilik[$index]['nama_pemilik'],
                'no_telp'         => $profilPemilik[$index]['no_telp'],
                'foto_profil_path'=> $profilPemilik[$index]['foto_profil_path'],
            ]);
        }
    }
}
