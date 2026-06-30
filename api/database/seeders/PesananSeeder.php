<?php

namespace Database\Seeders;

use App\Models\Kantin;
use App\Models\Mahasiswa;
use App\Models\Menu;
use App\Models\Payment;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class PesananSeeder extends Seeder
{
    public function run(): void
    {
        $mahasiswaList = Mahasiswa::with('user')->orderBy('id')->get();
        $kantinList    = Kantin::orderBy('id')->get();

        // Helper: ambil menu berdasarkan kantin
        $menuByKantin = [];
        foreach ($kantinList as $kantin) {
            $menuByKantin[$kantin->id] = Menu::where('kantin_id', $kantin->id)->get();
        }

        // Helper: ambil pegawai/pemilik untuk dijadikan courier pada pesanan delivery
        $pegawaiUser = User::where('role', 'pegawai')->first();
        $pemilikUser = User::where('role', 'pemilik')->first();

        // --- Skenario Pesanan ----------------------------------------------------
        // Status yang dipakai di mobile:
        // - Tab "Baru Masuk": dibayar, pending
        // - Tab "Diproses"  : dimasak, dalam_perjalanan
        // - Tab "Selesai"   : selesai
        // - Lainnya         : ditolak, dibatalkan, menunggu_pembayaran

        $scenarios = [
            // =====================================================================
            // PESANAN BARU MASUK (status: dibayar)
            // =====================================================================

            // 1. Baru masuk dine-in - Budi di Kantin Teknik
            [
                'mahasiswa_index' => 0,
                'kantin_index'    => 0,
                'tipe_pesanan'    => 'dine-in',
                'status_pesanan'  => 'dibayar',
                'nomor_antrian'   => 'A-001',
                'catatan_pesanan' => 'Tidak pedas ya kak',
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'tidak pedas']],
                    ['menu_index' => 2, 'jumlah' => 2, 'varian' => ['Suhu' => 'es']],
                ],
                'payment' => [
                    'metode_bayar'       => 'qris',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(5),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via QRIS',
                ],
            ],

            // 2. Baru masuk take-away - Siti di Kantin TN
            [
                'mahasiswa_index' => 1,
                'kantin_index'    => 1,
                'tipe_pesanan'    => 'take-away',
                'status_pesanan'  => 'dibayar',
                'nomor_antrian'   => 'A-001',
                'catatan_pesanan' => 'Sambalnya pisah ya',
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Nasi' => 'nasi putih']],
                    ['menu_index' => 3, 'jumlah' => 1, 'varian' => ['Suhu' => 'es', 'Ukuran' => 'regular']],
                ],
                'payment' => [
                    'metode_bayar'       => 'transfer',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(3),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via transfer bank',
                ],
            ],

            // 3. Baru masuk delivery - Andi di Kantin GKT
            [
                'mahasiswa_index' => 2,
                'kantin_index'    => 2,
                'tipe_pesanan'    => 'delivery',
                'status_pesanan'  => 'dibayar',
                'nomor_antrian'   => 'A-001',
                'catatan_pesanan' => 'Tolong taruh di depan pintu Gedung Teknik Sipil',
                'courier_user'    => null,
                'alamat_pengantaran' => 'Gedung Teknik Sipil Lt.2 Ruang D203, Polines Tembalang',
                'dest_lat'        => -7.0525,
                'dest_lng'        => 110.4360,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 2, 'varian' => ['Level Pedas' => 'level 3', 'Bagian Ayam' => 'dada']],
                    ['menu_index' => 2, 'jumlah' => 2, 'varian' => ['Gula' => 'normal']],
                ],
                'payment' => [
                    'metode_bayar'       => 'midtrans',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(2),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> Str::random(32),
                    'log_transaksi'      => 'Pembayaran berhasil via Midtrans',
                ],
            ],

            // =====================================================================
            // SEDANG DIMASAK (status: dimasak)
            // =====================================================================

            // 4. Sedang dimasak dine-in - Dewi di Kantin Teknik
            [
                'mahasiswa_index' => 3,
                'kantin_index'    => 0,
                'tipe_pesanan'    => 'dine-in',
                'status_pesanan'  => 'dimasak',
                'nomor_antrian'   => 'A-002',
                'catatan_pesanan' => 'Ekstra nasi dong',
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 1, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'pedas']],
                    ['menu_index' => 2, 'jumlah' => 1, 'varian' => ['Suhu' => 'panas']],
                ],
                'payment' => [
                    'metode_bayar'       => 'qris',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(15),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via QRIS',
                ],
            ],

            // 5. Sedang dimasak take-away - Rizky di Kantin TN
            [
                'mahasiswa_index' => 4,
                'kantin_index'    => 1,
                'tipe_pesanan'    => 'take-away',
                'status_pesanan'  => 'dimasak',
                'nomor_antrian'   => 'A-002',
                'catatan_pesanan' => null,
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 1, 'jumlah' => 1, 'varian' => ['Jenis Mi' => 'bihun', 'Level Pedas' => 'biasa']],
                    ['menu_index' => 2, 'jumlah' => 1, 'varian' => ['Gula' => 'kurang manis']],
                ],
                'payment' => [
                    'metode_bayar'       => 'transfer',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(10),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via transfer bank',
                ],
            ],

            // 6. Sedang dimasak delivery - Budi di Kantin GKT
            [
                'mahasiswa_index' => 0,
                'kantin_index'    => 2,
                'tipe_pesanan'    => 'delivery',
                'status_pesanan'  => 'dimasak',
                'nomor_antrian'   => 'A-002',
                'catatan_pesanan' => 'Mohon dikemas rapi untuk delivery',
                'courier_user'    => null,
                'alamat_pengantaran' => 'Gedung Teknik Mesin Lt.1, Polines Tembalang',
                'dest_lat'        => -7.0528,
                'dest_lng'        => 110.4355,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'level 2', 'Bagian Ayam' => 'paha']],
                    ['menu_index' => 2, 'jumlah' => 1, 'varian' => ['Gula' => 'manis']],
                ],
                'payment' => [
                    'metode_bayar'       => 'midtrans',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(12),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> Str::random(32),
                    'log_transaksi'      => 'Pembayaran berhasil via Midtrans',
                ],
            ],

            // =====================================================================
            // DALAM PERJALANAN / PENGANTARAN (status: dalam_perjalanan)
            // =====================================================================

            // 7. Delivery dalam perjalanan - Siti di Kantin GKT, diantar pegawai
            [
                'mahasiswa_index' => 1,
                'kantin_index'    => 2,
                'tipe_pesanan'    => 'delivery',
                'status_pesanan'  => 'dalam_perjalanan',
                'nomor_antrian'   => 'A-003',
                'catatan_pesanan' => 'Jangan lupa sendok garpu ya',
                'courier_user'    => 'pegawai',
                'alamat_pengantaran' => 'Gedung Kuliah Bersama Lt.3, Polines Tembalang',
                'dest_lat'        => -7.0510,
                'dest_lng'        => 110.4358,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'level 1', 'Bagian Ayam' => 'sayap']],
                    ['menu_index' => 1, 'jumlah' => 1, 'varian' => ['Lauk 1' => 'ayam balado', 'Lauk 2' => 'perkedel', 'Sayur' => 'sayur asem']],
                ],
                'payment' => [
                    'metode_bayar'       => 'qris',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(25),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via QRIS',
                ],
            ],

            // 8. Delivery dalam perjalanan - Dewi di Kantin Teknik, diantar pemilik
            [
                'mahasiswa_index' => 3,
                'kantin_index'    => 0,
                'tipe_pesanan'    => 'delivery',
                'status_pesanan'  => 'dalam_perjalanan',
                'nomor_antrian'   => 'A-003',
                'catatan_pesanan' => 'Tunggu di lobby ya kak',
                'courier_user'    => 'pemilik',
                'alamat_pengantaran' => 'Gedung Administrasi Pusat, Polines Tembalang',
                'dest_lat'        => -7.0505,
                'dest_lng'        => 110.4362,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'pedas']],
                    ['menu_index' => 2, 'jumlah' => 2, 'varian' => ['Suhu' => 'es']],
                ],
                'payment' => [
                    'metode_bayar'       => 'transfer',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subMinutes(20),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via transfer bank',
                ],
            ],

            // =====================================================================
            // PESANAN SELESAI
            // =====================================================================

            // 9. Selesai dine-in - Rizky di Kantin Teknik
            [
                'mahasiswa_index' => 4,
                'kantin_index'    => 0,
                'tipe_pesanan'    => 'dine-in',
                'status_pesanan'  => 'selesai',
                'nomor_antrian'   => 'A-004',
                'catatan_pesanan' => null,
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'extra pedas']],
                ],
                'payment' => [
                    'metode_bayar'       => 'qris',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subHours(3),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via QRIS',
                ],
            ],

            // 10. Selesai delivery - Andi di Kantin TN, diantar pegawai
            [
                'mahasiswa_index' => 2,
                'kantin_index'    => 1,
                'tipe_pesanan'    => 'delivery',
                'status_pesanan'  => 'selesai',
                'nomor_antrian'   => 'A-003',
                'catatan_pesanan' => null,
                'courier_user'    => 'pegawai',
                'alamat_pengantaran' => 'Perpustakaan Polines Lt.2, Tembalang',
                'dest_lat'        => -7.0508,
                'dest_lng'        => 110.4360,
                'menu_items'      => [
                    ['menu_index' => 1, 'jumlah' => 1, 'varian' => ['Jenis Mi' => 'mi kuning', 'Level Pedas' => 'pedas']],
                    ['menu_index' => 2, 'jumlah' => 1, 'varian' => ['Gula' => 'tanpa gula']],
                ],
                'payment' => [
                    'metode_bayar'       => 'qris',
                    'status_bayar'       => 'berhasil',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subHours(5),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pembayaran berhasil via QRIS',
                ],
            ],

            // =====================================================================
            // PESANAN LAINNYA (pending, ditolak, dibatalkan)
            // =====================================================================

            // 11. Menunggu pembayaran - Dewi di Kantin TN
            [
                'mahasiswa_index' => 3,
                'kantin_index'    => 1,
                'tipe_pesanan'    => 'dine-in',
                'status_pesanan'  => 'menunggu_pembayaran',
                'nomor_antrian'   => null,
                'catatan_pesanan' => null,
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Nasi' => 'nasi uduk']],
                ],
                'payment' => [
                    'metode_bayar'       => 'midtrans',
                    'status_bayar'       => 'pending',
                    'nominal'            => null,
                    'waktu_bayar'        => null,
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> Str::random(32),
                    'log_transaksi'      => 'Menunggu pembayaran dari pelanggan',
                ],
            ],

            // 12. Ditolak kantin - Siti di Kantin Teknik
            [
                'mahasiswa_index' => 1,
                'kantin_index'    => 0,
                'tipe_pesanan'    => 'take-away',
                'status_pesanan'  => 'ditolak',
                'nomor_antrian'   => null,
                'catatan_pesanan' => null,
                'alasan_penolakan'=> 'Bahan habis, maaf pesanan tidak bisa diproses hari ini.',
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 1, 'jumlah' => 2, 'varian' => ['Level Pedas' => 'pedas']],
                ],
                'payment' => [
                    'metode_bayar'       => 'qris',
                    'status_bayar'       => 'refund',
                    'nominal'            => null,
                    'waktu_bayar'        => now()->subHours(1),
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pesanan ditolak kantin, refund diproses',
                ],
            ],

            // 13. Dibatalkan pelanggan - Rizky di Kantin GKT
            [
                'mahasiswa_index' => 4,
                'kantin_index'    => 2,
                'tipe_pesanan'    => 'dine-in',
                'status_pesanan'  => 'dibatalkan',
                'nomor_antrian'   => null,
                'catatan_pesanan' => null,
                'courier_user'    => null,
                'menu_items'      => [
                    ['menu_index' => 0, 'jumlah' => 1, 'varian' => ['Level Pedas' => 'level 5', 'Bagian Ayam' => 'dada']],
                    ['menu_index' => 2, 'jumlah' => 1, 'varian' => ['Gula' => 'kurang manis']],
                ],
                'payment' => [
                    'metode_bayar'       => 'transfer',
                    'status_bayar'       => 'gagal',
                    'nominal'            => null,
                    'waktu_bayar'        => null,
                    'midtrans_order_id'  => 'ORDER-' . strtoupper(Str::random(8)),
                    'midtrans_snap_token'=> null,
                    'log_transaksi'      => 'Pesanan dibatalkan oleh pelanggan sebelum pembayaran',
                ],
            ],
        ];

        // --- Generate 20 Pesanan Baru Masuk per Kantin ---
        $layananTipes = ['dine-in', 'take-away', 'delivery'];
        $metodeBayar = ['qris', 'transfer', 'midtrans'];

        // Alamat pengantaran khas Polines
        $alamatDelivery = [
            'Gedung Teknik Sipil Lt.1, Polines Tembalang',
            'Gedung Teknik Mesin Lt.2, Polines Tembalang',
            'Gedung Teknik Elektro Lab Komputer, Polines Tembalang',
            'Gedung Akuntansi Lt.3, Polines Tembalang',
            'Gedung Administrasi Bisnis Lt.1, Polines Tembalang',
            'Perpustakaan Polines Lt.2, Tembalang',
            'Gedung Kuliah Bersama Lt.1, Polines Tembalang',
            'Gedung Kuliah Terpadu Lt.2, Polines Tembalang',
            'Ruang Dosen Teknik Elektro, Polines Tembalang',
            'Student Center Polines, Tembalang',
        ];

        foreach ($kantinList as $kantinIndex => $kantin) {
            $menuListKantin = $menuByKantin[$kantin->id]->values();
            $menuCount = $menuListKantin->count();

            if ($menuCount === 0) continue;

            for ($i = 0; $i < 20; $i++) {
                $mahasiswaIndex = rand(0, $mahasiswaList->count() - 1);
                $tipe = $layananTipes[$i % 3]; // bergantian metode layanan
                $mbayar = $metodeBayar[$i % 3]; // bergantian metode bayar

                $numItems = rand(1, 2);
                $menuItems = [];
                for ($j = 0; $j < $numItems; $j++) {
                    $mIndex = rand(0, $menuCount - 1);
                    $menuItems[] = [
                        'menu_index' => $mIndex,
                        'jumlah' => rand(1, 3),
                        'varian' => null,
                    ];
                }

                $scenarios[] = [
                    'mahasiswa_index' => $mahasiswaIndex,
                    'kantin_index'    => $kantinIndex,
                    'tipe_pesanan'    => $tipe,
                    'status_pesanan'  => 'dibayar',
                    'nomor_antrian'   => 'A-' . str_pad($i + 100, 3, '0', STR_PAD_LEFT),
                    'catatan_pesanan' => 'Pesanan tambahan auto ' . ($i + 1),
                    'courier_user'    => null,
                    'alamat_pengantaran' => $tipe === 'delivery' ? $alamatDelivery[array_rand($alamatDelivery)] : null,
                    'dest_lat'        => $tipe === 'delivery' ? -7.0519 + (rand(-100, 100) / 100000) : null,
                    'dest_lng'        => $tipe === 'delivery' ? 110.4353 + (rand(-100, 100) / 100000) : null,
                    'menu_items'      => $menuItems,
                    'payment' => [
                        'metode_bayar'       => $mbayar,
                        'status_bayar'       => 'berhasil',
                        'nominal'            => null,
                        'waktu_bayar'        => now()->subMinutes(rand(1, 120)),
                        'midtrans_order_id'  => 'ORDER-AUTO-' . strtoupper(Str::random(8)),
                        'midtrans_snap_token'=> $mbayar === 'midtrans' ? Str::random(32) : null,
                        'log_transaksi'      => 'Pembayaran massal via ' . $mbayar,
                    ],
                ];
            }
        }

        // --- Generate 5 Pesanan Selesai per Mahasiswa ---
        foreach ($mahasiswaList as $mIndex => $mahasiswa) {
            for ($i = 0; $i < 5; $i++) {
                $kantinIndex = rand(0, $kantinList->count() - 1);
                $kantin = $kantinList[$kantinIndex];
                
                // Skip jika kantin tidak punya menu
                if (!isset($menuByKantin[$kantin->id]) || $menuByKantin[$kantin->id]->isEmpty()) {
                    continue;
                }

                $menuCount = $menuByKantin[$kantin->id]->count();
                $tipe = $layananTipes[$i % 3];
                $mbayar = $metodeBayar[$i % 3];

                $numItems = rand(1, 3);
                $menuItems = [];
                for ($j = 0; $j < $numItems; $j++) {
                    $mIndexMenu = rand(0, $menuCount - 1);
                    $menuItems[] = [
                        'menu_index' => $mIndexMenu,
                        'jumlah' => rand(1, 2),
                        'varian' => null,
                    ];
                }

                $waktuSelesai = now()->subDays(rand(1, 30))->subHours(rand(1, 24));

                $scenarios[] = [
                    'mahasiswa_index' => $mIndex,
                    'kantin_index'    => $kantinIndex,
                    'tipe_pesanan'    => $tipe,
                    'status_pesanan'  => 'selesai',
                    'nomor_antrian'   => 'A-' . str_pad(rand(1, 999), 3, '0', STR_PAD_LEFT),
                    'catatan_pesanan' => 'Pesanan riwayat ' . ($i + 1),
                    'courier_user'    => $tipe === 'delivery' ? (rand(0, 1) ? 'pegawai' : 'pemilik') : null,
                    'alamat_pengantaran' => $tipe === 'delivery' ? $alamatDelivery[array_rand($alamatDelivery)] : null,
                    'dest_lat'        => $tipe === 'delivery' ? -7.0519 + (rand(-100, 100) / 100000) : null,
                    'dest_lng'        => $tipe === 'delivery' ? 110.4353 + (rand(-100, 100) / 100000) : null,
                    'menu_items'      => $menuItems,
                    'created_at'      => $waktuSelesai,
                    'updated_at'      => $waktuSelesai,
                    'payment' => [
                        'metode_bayar'       => $mbayar,
                        'status_bayar'       => 'berhasil',
                        'nominal'            => null,
                        'waktu_bayar'        => $waktuSelesai,
                        'midtrans_order_id'  => 'ORDER-HIS-' . strtoupper(Str::random(8)),
                        'midtrans_snap_token'=> null,
                        'log_transaksi'      => 'Pembayaran riwayat via ' . $mbayar,
                    ],
                ];
            }
        }

        // --- Generate 2 Pesanan Selesai (Belum Dirating) per Mahasiswa ---
        foreach ($mahasiswaList as $mIndex => $mahasiswa) {
            for ($i = 0; $i < 2; $i++) {
                $kantinIndex = rand(0, $kantinList->count() - 1);
                $kantin = $kantinList[$kantinIndex];
                
                // Skip jika kantin tidak punya menu
                if (!isset($menuByKantin[$kantin->id]) || $menuByKantin[$kantin->id]->isEmpty()) {
                    continue;
                }

                $menuCount = $menuByKantin[$kantin->id]->count();
                $tipe = $layananTipes[$i % 3];
                $mbayar = $metodeBayar[$i % 3];

                $numItems = rand(1, 2);
                $menuItems = [];
                for ($j = 0; $j < $numItems; $j++) {
                    $mIndexMenu = rand(0, $menuCount - 1);
                    $menuItems[] = [
                        'menu_index' => $mIndexMenu,
                        'jumlah' => rand(1, 2),
                        'varian' => null,
                    ];
                }

                $waktuSelesai = now()->subDays(rand(1, 5))->subHours(rand(1, 24));

                $scenarios[] = [
                    'mahasiswa_index' => $mIndex,
                    'kantin_index'    => $kantinIndex,
                    'tipe_pesanan'    => $tipe,
                    'status_pesanan'  => 'selesai',
                    'nomor_antrian'   => 'A-' . str_pad(rand(1, 999), 3, '0', STR_PAD_LEFT),
                    'catatan_pesanan' => 'Pesanan riwayat belum dirating ' . ($i + 1),
                    'courier_user'    => $tipe === 'delivery' ? (rand(0, 1) ? 'pegawai' : 'pemilik') : null,
                    'alamat_pengantaran' => $tipe === 'delivery' ? $alamatDelivery[array_rand($alamatDelivery)] : null,
                    'dest_lat'        => $tipe === 'delivery' ? -7.0519 + (rand(-100, 100) / 100000) : null,
                    'dest_lng'        => $tipe === 'delivery' ? 110.4353 + (rand(-100, 100) / 100000) : null,
                    'menu_items'      => $menuItems,
                    'created_at'      => $waktuSelesai,
                    'updated_at'      => $waktuSelesai,
                    'payment' => [
                        'metode_bayar'       => $mbayar,
                        'status_bayar'       => 'berhasil',
                        'nominal'            => null,
                        'waktu_bayar'        => $waktuSelesai,
                        'midtrans_order_id'  => 'ORDER-UNRATED-' . strtoupper(Str::random(8)),
                        'midtrans_snap_token'=> null,
                        'log_transaksi'      => 'Pembayaran riwayat via ' . $mbayar,
                    ],
                ];
            }
        }

        foreach ($scenarios as $s) {
            $mahasiswa = $mahasiswaList[$s['mahasiswa_index']];
            $kantin    = $kantinList[$s['kantin_index']];
            $menuList  = $menuByKantin[$kantin->id]->values(); // re-index

            // Tentukan courier user (pegawai/pemilik kantin terkait, atau null)
            $courierUserId = null;
            if (($s['courier_user'] ?? null) === 'pegawai') {
                $courierUserId = $pegawaiUser?->id;
            } elseif (($s['courier_user'] ?? null) === 'pemilik') {
                $courierUserId = $pemilikUser?->id;
            }

            // Hitung total harga
            $totalHarga = 0;
            foreach ($s['menu_items'] as $item) {
                $menu       = $menuList[$item['menu_index']];
                $harga      = (float) $menu->harga;
                $totalHarga += $harga * $item['jumlah'];
            }

            // Buat pesanan
            $pesananData = [
                'mahasiswa_id'       => $mahasiswa->id,
                'kantin_id'          => $kantin->id,
                'tipe_pesanan'       => $s['tipe_pesanan'],
                'status_pesanan'     => $s['status_pesanan'],
                'total_harga'        => $totalHarga,
                'nomor_antrian'      => $s['nomor_antrian'] ?? null,
                'catatan_pesanan'    => $s['catatan_pesanan'] ?? null,
                'alasan_penolakan'   => $s['alasan_penolakan'] ?? null,
                'courier_user_id'    => $courierUserId,
                'alamat_pengantaran' => $s['alamat_pengantaran'] ?? null,
                'dest_lat'           => $s['dest_lat'] ?? null,
                'dest_lng'           => $s['dest_lng'] ?? null,
                'qr_token'           => in_array($s['status_pesanan'], ['selesai', 'dalam_perjalanan'])
                                        ? Str::uuid()->toString()
                                        : null,
            ];

            if (isset($s['created_at'])) {
                $pesananData['created_at'] = $s['created_at'];
            }
            if (isset($s['updated_at'])) {
                $pesananData['updated_at'] = $s['updated_at'];
            }

            // Nonaktifkan auto-generate nomor antrian dari model event agar
            // seeder bisa set nomor_antrian secara eksplisit
            $pesanan = Pesanan::withoutEvents(function () use ($pesananData) {
                return Pesanan::create($pesananData);
            });

            // Buat detail pesanan
            foreach ($s['menu_items'] as $item) {
                $menu        = $menuList[$item['menu_index']];
                $harga       = (float) $menu->harga;
                $subtotal    = $harga * $item['jumlah'];

                PesananDetail::create([
                    'pesanan_id'       => $pesanan->id,
                    'menu_id'          => $menu->id,
                    'harga_saat_beli'  => $harga,
                    'jumlah_pesanan'   => $item['jumlah'],
                    'subtotal'         => $subtotal,
                    'varian_snapshot'  => $item['varian'] ?? null,
                ]);
            }

            // Buat payment
            $payData            = $s['payment'];
            $payData['nominal'] = $payData['nominal'] ?? (int) $totalHarga;

            Payment::create([
                'pesanan_id'          => $pesanan->id,
                'metode_bayar'        => $payData['metode_bayar'],
                'status_bayar'        => $payData['status_bayar'],
                'log_transaksi'       => $payData['log_transaksi'],
                'nominal'             => $payData['nominal'],
                'waktu_bayar'         => $payData['waktu_bayar'],
                'midtrans_order_id'   => $payData['midtrans_order_id'],
                'midtrans_snap_token' => $payData['midtrans_snap_token'],
            ]);
        }
    }
}