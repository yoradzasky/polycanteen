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

        // Distribusi: Kantin Teknik → 2 pegawai, Kantin TN → 1 pegawai, Kantin GKT → 1 pegawai
        $profilPegawai = [
            [
                'nama_karyawan'    => 'Ahmad Fauzi',
                'no_telp'          => '083344556677',
                'foto_profil_path' => null,
                'kantin_index'     => 0, // Kantin Teknik (Kantek)
            ],
            [
                'nama_karyawan'    => 'Lina Marlina',
                'no_telp'          => '083344556678',
                'foto_profil_path' => null,
                'kantin_index'     => 0, // Kantin Teknik (Kantek)
            ],
            [
                'nama_karyawan'    => 'Teguh Santoso',
                'no_telp'          => '083344556679',
                'foto_profil_path' => null,
                'kantin_index'     => 1, // Kantin Tata Niaga (TN)
            ],
            [
                'nama_karyawan'    => 'Rina Oktavia',
                'no_telp'          => '083344556680',
                'foto_profil_path' => null,
                'kantin_index'     => 2, // Kantin GKT
            ],
        ];

        foreach ($pegawaiUsers as $index => $user) {
            if (isset($profilPegawai[$index])) {
                $profil = $profilPegawai[$index];
            } else {
                $profil = [
                    'nama_karyawan'    => $user->nama_lengkap,
                    'no_telp'          => '08' . rand(1000000000, 9999999999),
                    'kantin_index'     => rand(0, count($kantinList) - 1),
                ];
            }

            if (!isset($kantinList[$profil['kantin_index']])) {
                $profil['kantin_index'] = 0;
            }

            $foto = 'https://i.pravatar.cc/150?u=' . urlencode($profil['nama_karyawan']);

            Pegawai::create([
                'user_id'          => $user->id,
                'kantin_id'        => $kantinList[$profil['kantin_index']]->id,
                'nama_karyawan'    => $profil['nama_karyawan'],
                'no_telp'          => $profil['no_telp'],
                'foto_profil_path' => $foto,
            ]);
        }
    }
}
