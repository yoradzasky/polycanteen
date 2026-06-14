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

        // === TEST USER PEMILIK (Bu Mariyam) ===
        $testKantin = Kantin::create([
            'nama_kantin' => 'Kantin Bu Mariyam',
            'lokasi_lengkap' => 'Kampus Politeknik',
            'longitude' => 107.6015,
            'latitude' => -6.8957,
            'status_toko' => 'buka',
            'logo_path' => null 
        ]);

        $testUser = User::create([
            'username' => 'Bu Mariyam',
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
            'username' => 'Pak Budi Pegawai',
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
        // 2. Kantin (Total 11 termasuk Bu Mariyam)
        $kantins = [$testKantin]; // Masukkan Bu Mariyam ke array agar ikut di-seed menu-nya
        for ($i = 1; $i <= 10; $i++) {
            $kantins[] = Kantin::create([
                'nama_kantin' => 'Kantin ' . $faker->company,
                'lokasi_lengkap' => $faker->address,
                'longitude' => $faker->longitude,
                'latitude' => $faker->latitude,
                'status_toko' => 'buka',
                'logo_path' => 'https://picsum.photos/seed/' . rand(1, 1000) . '/400/400'
            ]);
        }

        // 3 & 4. Pemilik & User Pemilik (10 records tambahan)
        // Lewati index 0 karena itu kantin Bu Mariyam yang sudah ada pemiliknya
        for ($i = 1; $i <= 10; $i++) {
            $kantin = $kantins[$i];
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

        // 7 & 8. Mahasiswa & User Mahasiswa (15 Mahasiswa)
        $mahasiswas = [];
        $daftarJurusan = [
            'Teknik Elektro', 'Teknik Mesin', 'Akuntansi', 
            'Teknik Sipil', 'Administrasi Bisnis', 'Teknik Informatika'
        ];

        for ($i = 1; $i <= 15; $i++) {
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
                'jurusan' => $daftarJurusan[array_rand($daftarJurusan)], 
                'no_telp' => $faker->phoneNumber,
                'masa_aktif' => now()->addYears(4)->toDateString(),
                'foto_profil_path' => null
            ]);
        }

        // 9. Menu (Masing-masing kantin 10 Menu -> Total 110 Menu)
        // Kita simpan ke dalam array 2 dimensi agar mudah diambil per kantin saat membuat order
        $menusByKantin = [];
        foreach ($kantins as $kantin) {
            $menusByKantin[$kantin->id] = [];
            for ($j = 1; $j <= 10; $j++) {
                $menu = Menu::create([
                    'kantin_id' => $kantin->id,
                    'nama_item' => $faker->randomElement(['Nasi', 'Es', 'Ayam', 'Mie', 'Kopi', 'Jus']) . ' ' . $faker->word,
                    'kategori' => $faker->randomElement(['Makanan', 'Minuman', 'Cemilan']),
                    'harga' => $faker->numberBetween(5, 25) * 1000, // Kelipatan ribuan (5000 - 25000)
                    'foto_menu' => 'https://picsum.photos/seed/' . rand(1, 1000) . '/400/400',
                    'status_stok' => true,
                    'deskripsi' => $faker->sentence,
                    'estimasi_waktu' => $faker->numberBetween(2, 15), // Estimasi acak 2-15 menit
                    'pilihan_layanan' => ['dine_in', 'takeaway'],
                    'varian' => [
                        [
                            'nama' => 'Pilihan Porsi', 
                            'tipe' => 'wajib',
                            'pilihan' => [
                                ['nama' => 'Original', 'harga' => 0],
                                ['nama' => 'Jumbo', 'harga' => 3000]
                            ]
                        ],
                        [
                            'nama' => 'Topping Tambahan', 
                            'tipe' => 'opsional',
                            'pilihan' => [
                                ['nama' => 'Telur Dadar', 'harga' => 4000],
                                ['nama' => 'Sosis', 'harga' => 3000]
                            ]
                        ]
                    ],
                ]);
                $menusByKantin[$kantin->id][] = $menu;
            }
        }

        // 10. Pesanan, PesananDetail, Payment, & Ulasan
        // PERBAIKAN: Setiap mahasiswa akan melakukan 10 kali transaksi (Total 150 Pesanan)
        $nomorUrutAntrian = 1;

        foreach ($mahasiswas as $mhs) {
            for ($k = 0; $k < 10; $k++) { 
                $kantinPilihan = $faker->randomElement($kantins);
                $menuKantinTersedia = $menusByKantin[$kantinPilihan->id];
                $jumlahMacamMenu = $faker->numberBetween(2, 4);
                $menuDipesan = $faker->randomElements($menuKantinTersedia, $jumlahMacamMenu);

                $totalHargaPesanan = 0;
                $detailsToInsert = [];

                foreach ($menuDipesan as $menu) {
                    $qty = $faker->numberBetween(1, 3);
                    $hargaBeli = $menu->harga;
                    $hargaTopping = 2000;
                    $subtotalItem = ($hargaBeli + $hargaTopping) * $qty;
                    
                    $totalHargaPesanan += $subtotalItem;

                    $detailsToInsert[] = [
                        'menu_id' => $menu->id,
                        'harga_saat_beli' => $hargaBeli,
                        'jumlah_pesanan' => $qty,
                        'subtotal' => $subtotalItem,
                        'varian_snapshot' => [
                            'Pilihan Porsi' => ['nama' => 'Original', 'harga' => 0]
                        ],
                    ];
                }

                // PERBAIKAN: Selesai mendominasi 70% dari total pesanan, sisanya acak untuk variasi
                $statusPesananAcak = $faker->randomElement([
                    'selesai', 'selesai', 'selesai', 'selesai', 'selesai', 'selesai', 'selesai', 
                    'dibayar', 'dimasak', 'dalam_perjalanan', 'ditolak'
                ]);

                $pesanan = Pesanan::create([
                    'mahasiswa_id' => $mhs->id,
                    'kantin_id' => $kantinPilihan->id,
                    'tipe_pesanan' => $faker->randomElement(['dine_in', 'take_away']),
                    'status_pesanan' => $statusPesananAcak,
                    'total_harga' => $totalHargaPesanan,
                    'nomor_antrian' => 'A-' . str_pad($nomorUrutAntrian++, 3, '0', STR_PAD_LEFT),
                    'catatan_pesanan' => $faker->sentence
                ]);

                // Logika Payment: Jika ditolak, anggap saja gagal/refund. Selain itu sukses.
                $statusBayar = ($statusPesananAcak === 'ditolak') ? 'gagal' : 'sukses';

                Payment::create([
                    'pesanan_id' => $pesanan->id,
                    'metode_bayar' => 'qris',
                    'status_bayar' => $statusBayar,
                    'log_transaksi' => '{"transaction_status":"' . ($statusBayar == 'sukses' ? 'settlement' : 'cancel') . '"}',
                    'nominal' => $totalHargaPesanan,
                    'waktu_bayar' => now(),
                    'midtrans_order_id' => $pesanan->nomor_antrian,
                    'midtrans_snap_token' => 'token_' . $faker->uuid
                ]);

                // Buat Detail Pesanan & Ulasan per Menu
                foreach ($detailsToInsert as $detail) {
                    PesananDetail::create([
                        'pesanan_id' => $pesanan->id,
                        'menu_id' => $detail['menu_id'],
                        'harga_saat_beli' => $detail['harga_saat_beli'],
                        'jumlah_pesanan' => $detail['jumlah_pesanan'],
                        'subtotal' => $detail['subtotal'],
                        'varian_snapshot' => $detail['varian_snapshot'],
                    ]);

                    // Ulasan HANYA dibuat jika status pesanannya 'selesai'
                    if ($statusPesananAcak === 'selesai') {
                        Ulasan::create([
                            'pesanan_id' => $pesanan->id,
                            'mahasiswa_id' => $mhs->id,
                            'kantin_id' => $kantinPilihan->id,
                            'menu_id' => $detail['menu_id'],
                            'rating' => $faker->numberBetween(3, 5), 
                            'komentar' => $faker->randomElement([
                                'Enak banget!', 'Lumayan lah', 'Porsinya pas', 'Bumbunya kerasa', 'Rekomended!'
                            ])
                        ]);
                    }
                }
            }
        }
    }
}