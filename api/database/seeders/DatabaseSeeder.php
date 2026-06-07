<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     * Urutan penting karena ada foreign key constraints.
     */
    public function run(): void
    {
        $this->call([
            // 1. Users (independen)
            UserSeeder::class,

            // 2. Kantin (independen)
            KantinSeeder::class,

            // 3. Profil turunan dari User + Kantin
            MahasiswaSeeder::class,
            PemilikSeeder::class,
            PegawaiSeeder::class,

            // 4. Menu (butuh Kantin)
            MenuSeeder::class,

            // 5. Pesanan + Detail + Payment + Keranjang + Ulasan
            PesananSeeder::class,
            KeranjangSeeder::class,
            UlasanSeeder::class,
        ]);
    }
}
