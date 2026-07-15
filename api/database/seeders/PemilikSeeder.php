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
                'nama_pemilik'     => 'Hendra Wijaya',
                'no_telp'          => '082111222333',
                'foto_profil_path' => null,
            ],
            [
                'nama_pemilik'     => 'Sri Wahyuni',
                'no_telp'          => '082111222334',
                'foto_profil_path' => null,
            ],
            [
                'nama_pemilik'     => 'Agus Mulyono',
                'no_telp'          => '082111222335',
                'foto_profil_path' => null,
            ],
        ];

        // Setiap pemilik memiliki 1 kantin (1-to-1 sesuai urutan)
        foreach ($pemilikUsers as $index => $user) {
            if (isset($profilPemilik[$index])) {
                $profil = $profilPemilik[$index];
            } else {
                $profil = [
                    'nama_pemilik' => $user->nama_lengkap,
                    'no_telp'      => '08' . rand(1000000000, 9999999999),
                ];
            }

            $kantinId = isset($kantinList[$index]) ? $kantinList[$index]->id : $kantinList[0]->id;
            $foto = 'https://i.pravatar.cc/150?u=' . urlencode($profil['nama_pemilik']);
            
            Pemilik::create([
                'user_id'          => $user->id,
                'kantin_id'        => $kantinId,
                'nama_pemilik'     => $profil['nama_pemilik'],
                'no_telp'          => $profil['no_telp'],
                'foto_profil_path' => $foto,
            ]);
        }
    }
}
