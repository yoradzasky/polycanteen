<?php

namespace Database\Seeders;

use App\Models\Kantin;
use Illuminate\Database\Seeder;

class KantinSeeder extends Seeder
{
    public function run(): void
    {
        // Koordinat kampus Polines Tembalang: -7.0519, 110.4353
        // Kantin-kantin di area kampus Politeknik Negeri Semarang
        $kantinList = [
            [
                'nama_kantin'    => 'Kantin Teknik (Kantek)',
                'lokasi_lengkap' => 'Dekat Gedung Teknik Mesin & Teknik Elektro, Kampus Polines, Jl. Prof. Soedarto, Tembalang, Semarang',
                'longitude'      => 110.4358,
                'latitude'       => -7.0522,
                'status_toko'    => 'buka',
                'logo_path'      => null,
            ],
            [
                'nama_kantin'    => 'Kantin Tata Niaga (TN)',
                'lokasi_lengkap' => 'Dekat Gedung Jurusan Akuntansi & Administrasi Bisnis, Kampus Polines, Jl. Prof. Soedarto, Tembalang, Semarang',
                'longitude'      => 110.4347,
                'latitude'       => -7.0515,
                'status_toko'    => 'buka',
                'logo_path'      => null,
            ],
            [
                'nama_kantin'    => 'Kantin GKT (Gedung Kuliah Terpadu)',
                'lokasi_lengkap' => 'Lantai 1 Gedung Kuliah Terpadu, Kampus Polines, Jl. Prof. Soedarto, Tembalang, Semarang',
                'longitude'      => 110.4352,
                'latitude'       => -7.0518,
                'status_toko'    => 'tutup',
                'logo_path'      => null,
            ],
        ];

        foreach ($kantinList as $kantin) {
            Kantin::create($kantin);
        }
    }
}
