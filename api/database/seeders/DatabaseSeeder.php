<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Kantin;
use App\Models\Mahasiswa;
use App\Models\Pemilik;
use App\Models\Pegawai;
use App\Models\Menu;
use App\Models\Keranjang;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Payment;
use App\Models\Ulasan;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     * Urutan penting karena ada foreign key constraints
     */
    public function run(): void
    {
        $faker = \Faker\Factory::create('id_ID');
        $this->call([
            // 1. Users (independen)
            UserSeeder::class,

            // 2. Kantin (independen)
            KantinSeeder::class,

            // 3. Profil turunan dari User + Kantin
            MahasiswaSeeder::class,
            PemilikSeeder::class,
            PegawaiSeeder::class,
            BuyerApplicationSeeder::class,

            // 4. Menu (butuh Kantin)
            MenuSeeder::class,

            // 5. Pesanan + Detail + Payment + Keranjang + Ulasan
            PesananSeeder::class,
            KeranjangSeeder::class,
            UlasanSeeder::class,
        ]);

        // === TEST USER PEMILIK (Bu Mariyam) ===
        $testKantin = Kantin::create([
            'nama_kantin' => 'Kantin Bu Mariyam',
            'lokasi_lengkap' => 'Kampus Politeknik',
            'longitude' => 107.6015,
            'latitude' => -6.8957,
            'status_toko' => 'buka',
            'logo_path' => null // Diubah dari foto_kantin menjadi logo_path
        ]);

        $testUser = User::create([
            'nama_lengkap' => 'Bu Mariyam',
            'email' => 'pemilik1@example.com',
            'password' => Hash::make('password123'),
            'role' => 'pemilik',
            'status_akun' => 'aktif',
            'foto_profile' => null,
        ]);

        Pemilik::create([
            'user_id' => $testUser->id,
            'kantin_id' => $testKantin->id,
            'nama_pemilik' => 'Bu Mariyam',
            'no_telp' => '081290142199',
            'foto_profil_path' => null
        ]);

        // === TEST USER PEGAWAI (Pak Budi) ===
        $testUserPegawai = User::create([
            'nama_lengkap' => 'Pak Budi Pegawai',
            'email' => 'pegawai1@example.com',
            'password' => Hash::make('password123'),
            'role' => 'pegawai',
            'status_akun' => 'aktif',
            'foto_profile' => null,
        ]);

        Pegawai::create([
            'user_id' => $testUserPegawai->id,
            'kantin_id' => $testKantin->id,
            'nama_karyawan' => 'Pak Budi',
            'no_telp' => '081234567890',
            'foto_profil_path' => null
        ]);

        // === REGULAR DATA (10 KANTINS) ===
        // 2. Kantin (10 records)
        $kantins = [];
        for ($i = 1; $i <= 10; $i++) {
            $kantins[] = Kantin::create([
                'nama_kantin' => 'Kantin ' . $faker->company,
                'lokasi_lengkap' => $faker->address,
                'longitude' => $faker->longitude,
                'latitude' => $faker->latitude,
                'status_toko' => 'buka',
                'logo_path' => null
            ]);
        }

        // 3 & 4. Pemilik & User Pemilik (10 records)
        foreach ($kantins as $kantin) {
            $user = User::create([
                'nama_lengkap' => 'pemilik_' . $kantin->id,
                'email' => 'pemilik' . $kantin->id . '@kantin.com',
                'password' => Hash::make('password123'),
                'role' => 'pemilik',
                'status_akun' => 'aktif',
            ]);
            Pemilik::create([
                'user_id' => $user->id,
                'kantin_id' => $kantin->id,
                'nama_pemilik' => $faker->name,
                'no_telp' => $faker->phoneNumber,
                'foto_profil_path' => null
            ]);
        }

        // 5 & 6. Pegawai & User Pegawai (10 records)
        foreach ($kantins as $kantin) {
            $user = User::create([
                'nama_lengkap' => 'pegawai_' . $kantin->id,
                'email' => 'pegawai' . $kantin->id . '@kantin.com',
                'password' => Hash::make('password123'),
                'role' => 'pegawai',
                'status_akun' => 'aktif',
            ]);
            Pegawai::create([
                'user_id' => $user->id,
                'kantin_id' => $kantin->id,
                'nama_karyawan' => $faker->name,
                'no_telp' => $faker->phoneNumber,
                'foto_profil_path' => null
            ]);
        }

        // 7 & 8. Mahasiswa & User Mahasiswa (10 records)
        $mahasiswas = [];
        for ($i = 1; $i <= 10; $i++) {
            $user = User::create([
                'nama_lengkap' => 'mahasiswa_' . $i,
                'email' => 'mahasiswa' . $i . '@kantin.com',
                'password' => Hash::make('password123'),
                'role' => 'mahasiswa',
                'status_akun' => 'aktif',
            ]);
            $mahasiswas[] = Mahasiswa::create([
                'user_id' => $user->id,
                'nama_mahasiswa' => $faker->name,
                'nim' => 'NIM' . $faker->unique()->randomNumber(8, true),
                'no_telp' => $faker->phoneNumber,
                'masa_aktif' => now()->addYears(4)->toDateString(),
                'foto_profil_path' => null
            ]);
        }

        // 9. Menu (10 records, 1 per kantin)
        $menus = [];
        foreach ($kantins as $kantin) {
            $menus[] = Menu::create([
                'kantin_id' => $kantin->id,
                'nama_item' => 'Menu ' . $faker->word,
                'kategori' => $faker->randomElement(['Makanan', 'Minuman', 'Cemilan']),
                'harga' => $faker->numberBetween(5000, 25000),
                'foto_menu' => null,
                'status_stok' => true,
                'deskripsi' => $faker->sentence,
                'estimasi_waktu' => $faker->numberBetween(5, 30),
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'varian' => [
                    [
                        'nama' => 'Ukuran',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'Biasa', 'harga' => 0],
                            ['nama' => 'Jumbo', 'harga' => 5000],
                        ]
                    ],
                    [
                        'nama' => 'Topping',
                        'tipe' => 'opsional',
                        'pilihan' => [
                            ['nama' => 'Keju', 'harga' => 3000],
                        ]
                    ]
                ]
            ]);
        }

        // 10. Keranjang (10 records)
        for ($i = 0; $i < 10; $i++) {
            Keranjang::create([
                'mahasiswa_id' => $mahasiswas[$i]->id,
                'menu_id' => $menus[$i]->id,
                'jumlah' => $faker->numberBetween(1, 3),
                'varian_selected' => [
                    'Ukuran' => ['nama' => 'Biasa', 'harga' => 0]
                ],
            ]);
        }

        // 11. Pesanan (10 records)
        // 12. PesananDetail (10 records)
        // 13. Payment (10 records)
        // 14. Ulasan (10 records)
        for ($i = 0; $i < 10; $i++) {
            $harga = $menus[$i]->harga;
            $jumlah = $faker->numberBetween(1, 3);
            $total_harga = $harga * $jumlah;

            // Khusus mahasiswa1@kantin.com ($i = 0), kita buat pesanan pending untuk testing
            $status_pesanan = ($i === 0) ? 'menunggu_pembayaran' : $faker->randomElement(['dibayar', 'dimasak', 'dalam_perjalanan', 'selesai', 'ditolak']);
            $status_bayar = ($i === 0) ? 'pending' : 'sukses';
            $waktu_bayar = ($i === 0) ? null : now();

            $pesanan = Pesanan::create([
                'mahasiswa_id' => $mahasiswas[$i]->id,
                'kantin_id' => $menus[$i]->kantin_id,
                'tipe_pesanan' => $faker->randomElement(['dine_in', 'take_away']),
                'status_pesanan' => $status_pesanan,
                'total_harga' => $total_harga,
                'nomor_antrian' => 'A-0' . str_pad($i + 1, 2, '0', STR_PAD_LEFT),
                'catatan_pesanan' => $faker->sentence
            ]);

            PesananDetail::create([
                'pesanan_id' => $pesanan->id,
                'menu_id' => $menus[$i]->id,
                'harga_saat_beli' => $harga,
                'jumlah_pesanan' => $jumlah,
                'subtotal' => $total_harga,
                'varian_snapshot' => [
                    'Ukuran' => ['nama' => 'Biasa', 'harga' => 0]
                ]
            ]);

            Payment::create([
                'pesanan_id' => $pesanan->id,
                'metode_bayar' => 'qris',
                'status_bayar' => $status_bayar,
                'log_transaksi' => ($i === 0) ? '{"transaction_status":"pending"}' : '{"transaction_status":"settlement"}',
                'nominal' => $total_harga,
                'waktu_bayar' => $waktu_bayar,
                'midtrans_order_id' => $pesanan->nomor_antrian,
                'midtrans_snap_token' => 'token_' . $faker->word
            ]);

            if ($status_pesanan === 'selesai') {
                Ulasan::create([
                    'pesanan_id' => $pesanan->id,
                    'mahasiswa_id' => $mahasiswas[$i]->id,
                    'kantin_id' => $menus[$i]->kantin_id,
                    'menu_id' => $menus[$i]->id,
                    'rating' => $faker->numberBetween(3, 5),
                    'komentar' => $faker->sentence
                ]);
            }
        }
    }
}
