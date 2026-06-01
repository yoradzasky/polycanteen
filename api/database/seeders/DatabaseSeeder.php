<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Mahasiswa;
use App\Models\Kantin;
use App\Models\Pemilik;
use App\Models\Pegawai;
use App\Models\Menu;
use App\Models\Keranjang;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Payment;
use App\Models\Ulasan;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Faker\Factory as Faker;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $faker = Faker::create('id_ID');

        // 1. Admin (User)
        User::create([
            'username' => 'Admin Utama',
            'email' => 'admin@kantin.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'status_akun' => 'aktif',
        ]);

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
                'username' => 'pemilik_' . $kantin->id,
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
                'username' => 'pegawai_' . $kantin->id,
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
                'username' => 'mahasiswa_' . $i,
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
                'pilihan_layanan' => ['dine_in', 'takeaway'],
                'varian' => [['nama' => 'Biasa', 'harga_tambahan' => 0], ['nama' => 'Jumbo', 'harga_tambahan' => 5000]],
                'topping' => [['nama' => 'Keju', 'harga' => 3000, 'required' => false]]
            ]);
        }

        // 10. Keranjang (10 records)
        for ($i = 0; $i < 10; $i++) {
            Keranjang::create([
                'mahasiswa_id' => $mahasiswas[$i]->id,
                'menu_id' => $menus[$i]->id,
                'jumlah' => $faker->numberBetween(1, 3),
                'varian_selected' => ['nama' => 'Biasa', 'harga_tambahan' => 0],
                'topping_selected' => [['nama' => 'Keju', 'harga' => 3000]],
            ]);
        }

        // 11. Pesanan (10 records)
        // 12. PesananDetail (10 records)
        // 13. Payment (10 records)
        // 14. Ulasan (10 records)
        for ($i = 0; $i < 10; $i++) {
            $harga = $menus[$i]->harga;
            $jumlah = $faker->numberBetween(1, 3);
            $total_harga = $harga * $jumlah + 3000; // include topping 3000

            $pesanan = Pesanan::create([
                'mahasiswa_id' => $mahasiswas[$i]->id,
                'kantin_id' => $menus[$i]->kantin_id,
                'tipe_pesanan' => $faker->randomElement(['dine_in', 'take_away']),
                // Status dibuat acak agar semua Tab di Flutter terisi
                'status_pesanan' => $faker->randomElement(['dibayar', 'dimasak', 'dalam_perjalanan', 'selesai', 'ditolak']),
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
                'varian_snapshot' => ['nama' => 'Biasa', 'harga_tambahan' => 0],
                'topping_snapshot' => [['nama' => 'Keju', 'harga' => 3000]]
            ]);

            Payment::create([
                'pesanan_id' => $pesanan->id,
                'metode_bayar' => 'qris',
                'status_bayar' => 'sukses',
                'log_transaksi' => '{"transaction_status":"settlement"}',
                'nominal' => $total_harga,
                'waktu_bayar' => now(),
                'midtrans_order_id' => $pesanan->nomor_antrian,
                'midtrans_snap_token' => 'token_' . $faker->word
            ]);

            Ulasan::create([
                'pesanan_id' => $pesanan->id,
                'mahasiswa_id' => $mahasiswas[$i]->id,
                'kantin_id' => $menus[$i]->kantin_id,
                'rating' => $faker->numberBetween(3, 5),
                'komentar' => $faker->sentence
            ]);
        }
    }
}