<?php

namespace Database\Seeders;

use App\Models\Kantin;
use Illuminate\Database\Seeder;

class KantinSeeder extends Seeder
{
    public function run(): void
    {
        $kantinList = [
            [
                'nama_kantin'    => 'Kantin Barokah',
                'lokasi_lengkap' => 'Gedung A Lantai 1, Politeknik Negeri Salatiga',
                'longitude'      => 110.4956789,
                'latitude'       => -7.3304321,
                'status_toko'    => 'buka',
                'logo_path'      => 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&auto=format&fit=crop',
            ],
            [
                'nama_kantin'    => 'Warung Bu Sri',
                'lokasi_lengkap' => 'Gedung B Samping Aula, Politeknik Negeri Salatiga',
                'longitude'      => 110.4961234,
                'latitude'       => -7.3307654,
                'status_toko'    => 'buka',
                'logo_path'      => 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&auto=format&fit=crop',
            ],
            [
                'nama_kantin'    => 'Kantin Pak Agus',
                'lokasi_lengkap' => 'Gedung C Dekat Parkiran, Politeknik Negeri Salatiga',
                'longitude'      => 110.4948765,
                'latitude'       => -7.3312345,
                'status_toko'    => 'tutup',
                'logo_path'      => 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&auto=format&fit=crop',
            ],
        ];

        foreach ($kantinList as $kantin) {
            Kantin::create($kantin);
        }
    }
}
