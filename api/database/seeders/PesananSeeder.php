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

        if ($mahasiswaList->isEmpty() || $kantinList->isEmpty()) {
            return;
        }

        $menuByKantin = [];
        foreach ($kantinList as $kantin) {
            $menuByKantin[$kantin->id] = Menu::where('kantin_id', $kantin->id)->get();
        }

        $pegawaiUser = User::where('role', 'pegawai')->first();
        $pemilikUser = User::where('role', 'pemilik')->first();

        $layananTipes = ['dine-in', 'take-away', 'delivery'];
        $metodeBayar = ['qris', 'transfer', 'midtrans'];
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

        $scenarios = [];
        $targetOrders = [
            ['count' => 5, 'status' => ['dibayar', 'menunggu_persetujuan']],
            ['count' => 5, 'status' => ['dimasak', 'dalam_perjalanan']],
            ['count' => 5, 'status' => ['selesai']], // 5 for today
            ['count' => 10, 'status' => ['selesai']], // 10 older ones
        ];

        foreach ($kantinList as $kantinIndex => $kantin) {
            if (!isset($menuByKantin[$kantin->id]) || $menuByKantin[$kantin->id]->count() == 0) {
                continue;
            }

            foreach ($targetOrders as $targetIdx => $target) {
                for ($i = 0; $i < $target['count']; $i++) {
                    $status = $target['status'][array_rand($target['status'])];
                    $mahasiswaIndex = rand(0, $mahasiswaList->count() - 1);
                    
                    $menuCount = $menuByKantin[$kantin->id]->count();
                    $tipe = $layananTipes[array_rand($layananTipes)];
                    $mbayar = $metodeBayar[array_rand($metodeBayar)];

                    $numItems = rand(1, 3);
                    $menuItems = [];
                    for ($j = 0; $j < $numItems; $j++) {
                        $mIndexMenu = rand(0, $menuCount - 1);
                        $selectedMenu = $menuByKantin[$kantin->id][$mIndexMenu];
                        
                        $varianSnapshot = [];
                        $tambahanHargaVarian = 0;
                        
                        $menuVarian = is_string($selectedMenu->varian) ? json_decode($selectedMenu->varian, true) : $selectedMenu->varian;
                        
                        if (!empty($menuVarian) && is_array($menuVarian)) {
                            foreach ($menuVarian as $vGroup) {
                                if ($vGroup['tipe'] === 'wajib' || rand(0, 1) === 1) {
                                    $pilihanList = $vGroup['pilihan'];
                                    $chosen = $pilihanList[array_rand($pilihanList)];
                                    $varianSnapshot[$vGroup['nama']] = $chosen['nama'];
                                    $tambahanHargaVarian += (float) ($chosen['harga'] ?? 0);
                                }
                            }
                        }

                        $menuItems[] = [
                            'menu_index' => $mIndexMenu,
                            'jumlah' => rand(1, 3),
                            'varian' => empty($varianSnapshot) ? null : $varianSnapshot,
                            'tambahan_harga_varian' => $tambahanHargaVarian,
                        ];
                    }
                    
                    // If it's the 4th target (older ones), make the date older
                    if ($targetIdx === 3) {
                        $waktuBuat = now()->subDays(rand(1, 30))->subMinutes(rand(60, 1440));
                    } else {
                        // For the new, process, and 5 today completed ones
                        $waktuBuat = now()->subMinutes(rand(60, 1440));
                    }
                    $waktuUpdate = (clone $waktuBuat)->addMinutes(rand(5, 45));
                    
                    $scenarios[] = [
                        'mahasiswa_index' => $mahasiswaIndex,
                        'kantin_index'    => $kantinIndex,
                        'tipe_pesanan'    => $tipe,
                        'status_pesanan'  => $status,
                        'nomor_antrian'   => 'A-' . str_pad(rand(1, 999), 3, '0', STR_PAD_LEFT),
                        'catatan_pesanan' => 'Pesanan ' . $status . ' random',
                        'courier_user'    => $tipe === 'delivery' ? (rand(0, 1) ? 'pegawai' : 'pemilik') : null,
                        'alamat_pengantaran' => $tipe === 'delivery' ? $alamatDelivery[array_rand($alamatDelivery)] : null,
                        'dest_lat'        => $tipe === 'delivery' ? -7.0519 + (rand(-100, 100) / 100000) : null,
                        'dest_lng'        => $tipe === 'delivery' ? 110.4353 + (rand(-100, 100) / 100000) : null,
                        'menu_items'      => $menuItems,
                        'created_at'      => $waktuBuat,
                        'updated_at'      => $waktuUpdate,
                        'payment' => [
                            'metode_bayar'       => $mbayar,
                            'status_bayar'       => 'berhasil',
                            'nominal'            => null,
                            'waktu_bayar'        => $waktuBuat,
                            'midtrans_order_id'  => 'ORDER-RND-' . strtoupper(Str::random(8)),
                            'midtrans_snap_token'=> null,
                            'log_transaksi'      => 'Pembayaran via ' . $mbayar,
                        ],
                    ];
                }
            }
        }

        foreach ($scenarios as $s) {
            $mahasiswa = $mahasiswaList[$s['mahasiswa_index']];
            $kantin    = $kantinList[$s['kantin_index']];
            $menuList  = $menuByKantin[$kantin->id]->values();

            $courierUserId = null;
            if (($s['courier_user'] ?? null) === 'pegawai') {
                $courierUserId = $pegawaiUser?->id;
            } elseif (($s['courier_user'] ?? null) === 'pemilik') {
                $courierUserId = $pemilikUser?->id;
            }

            $totalHarga = 0;
            foreach ($s['menu_items'] as $item) {
                $menu       = $menuList[$item['menu_index']];
                $hargaSatuan = (float) $menu->harga + ($item['tambahan_harga_varian'] ?? 0);
                $totalHarga += $hargaSatuan * $item['jumlah'];
            }

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
                'qr_token'           => in_array($s['status_pesanan'], ['selesai', 'dalam_perjalanan']) ? Str::uuid()->toString() : null,
                'created_at'         => $s['created_at'],
                'updated_at'         => $s['updated_at'],
            ];

            $pesanan = Pesanan::withoutEvents(function () use ($pesananData) {
                return Pesanan::create($pesananData);
            });

            foreach ($s['menu_items'] as $item) {
                $menu        = $menuList[$item['menu_index']];
                $hargaSatuan = (float) $menu->harga + ($item['tambahan_harga_varian'] ?? 0);
                $subtotal    = $hargaSatuan * $item['jumlah'];

                PesananDetail::create([
                    'pesanan_id'       => $pesanan->id,
                    'menu_id'          => $menu->id,
                    'harga_saat_beli'  => $hargaSatuan,
                    'jumlah_pesanan'   => $item['jumlah'],
                    'subtotal'         => $subtotal,
                    'varian_snapshot'  => $item['varian'] ?? null,
                ]);
            }

            $payData = $s['payment'];
            Payment::create([
                'pesanan_id'          => $pesanan->id,
                'metode_bayar'        => $payData['metode_bayar'],
                'status_bayar'        => $payData['status_bayar'],
                'log_transaksi'       => $payData['log_transaksi'],
                'nominal'             => $payData['nominal'] ?? (int) $totalHarga,
                'waktu_bayar'         => $payData['waktu_bayar'],
                'midtrans_order_id'   => $payData['midtrans_order_id'],
                'midtrans_snap_token' => $payData['midtrans_snap_token'],
            ]);
        }
    }
}