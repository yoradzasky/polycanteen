<?php

namespace Database\Seeders;

use App\Models\Kantin;
use App\Models\Menu;
use Illuminate\Database\Seeder;

class MenuSeeder extends Seeder
{
    public function run(): void
    {
        $kantinList = Kantin::orderBy('id')->get();

        // Pastikan ada minimal 3 kantin sebelum menjalankan seeder menu
        if ($kantinList->count() < 3) {
            return;
        }

        // ── Kantin 1: Kantin Teknik (Kantek) ─────────────────────────────
        $kantin1 = $kantinList[0];

        $menuKantin1 = [
            [
                'nama_item'       => 'Nasi Goreng Spesial',
                'kategori'        => 'Makanan',
                'harga'           => 15000,
                'status_stok'     => true,
                'deskripsi'       => 'Nasi goreng dengan telur, ayam, dan sayuran segar khas Kantek Polines.',
                'estimasi_waktu'  => 10,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Level Pedas',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'tidak pedas', 'harga' => 0],
                            ['nama' => 'pedas', 'harga' => 0],
                            ['nama' => 'extra pedas', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Topping Tambahan',
                        'tipe' => 'opsional',
                        'pilihan' => [
                            ['nama' => 'Telur Ceplok', 'harga' => 4000],
                            ['nama' => 'Sosis Bakar', 'harga' => 5000],
                            ['nama' => 'Kerupuk', 'harga' => 1000],
                        ]
                    ]
                ],
            ],
            [
                'nama_item'       => 'Mie Goreng Ayam',
                'kategori'        => 'Makanan',
                'harga'           => 13000,
                'status_stok'     => true,
                'deskripsi'       => 'Mie goreng dengan potongan ayam dan bumbu khas.',
                'estimasi_waktu'  => 8,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Level Pedas',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'tidak pedas', 'harga' => 0],
                            ['nama' => 'pedas', 'harga' => 0],
                            ['nama' => 'extra pedas', 'harga' => 0],
                        ]
                    ],
                ],
            ],
            [
                'nama_item'       => 'Es Teh Manis',
                'kategori'        => 'Minuman',
                'harga'           => 5000,
                'status_stok'     => true,
                'deskripsi'       => 'Teh manis dingin yang menyegarkan, cocok untuk cuaca Semarang.',
                'estimasi_waktu'  => 3,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Suhu',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'es', 'harga' => 0],
                            ['nama' => 'panas', 'harga' => 0],
                        ]
                    ],
                ],
            ],
            [
                'nama_item'       => 'Soto Ayam Semarang',
                'kategori'        => 'Makanan',
                'harga'           => 14000,
                'status_stok'     => false, // contoh stok habis
                'deskripsi'       => 'Soto ayam khas Semarang dengan kuah bening, bihun, tauge, dan perkedel.',
                'estimasi_waktu'  => 7,
                'pilihan_layanan' => ['makan_di_tempat'],
                'foto_menu'       => null,
                'varian'          => null,
            ],
        ];

        foreach ($menuKantin1 as $item) {
            Menu::create(array_merge(['kantin_id' => $kantin1->id], $item));
        }

        // ── Kantin 2: Kantin Tata Niaga (TN) ─────────────────────────────
        $kantin2 = $kantinList[1];

        $menuKantin2 = [
            [
                'nama_item'       => 'Pecel Komplit',
                'kategori'        => 'Makanan',
                'harga'           => 12000,
                'status_stok'     => true,
                'deskripsi'       => 'Pecel dengan sayuran rebus segar dan bumbu kacang khas, favorit mahasiswa Akuntansi.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Nasi',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'nasi putih', 'harga' => 0],
                            ['nama' => 'nasi uduk', 'harga' => 2000],
                            ['nama' => 'tanpa nasi', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Tambahan Lauk',
                        'tipe' => 'opsional',
                        'pilihan' => [
                            ['nama' => 'Telur Asin', 'harga' => 4000],
                            ['nama' => 'Tahu Goreng', 'harga' => 1000],
                            ['nama' => 'Tempe Mendoan', 'harga' => 1500],
                        ]
                    ]
                ],
            ],
            [
                'nama_item'       => 'Bakso Kuah',
                'kategori'        => 'Makanan',
                'harga'           => 15000,
                'status_stok'     => true,
                'deskripsi'       => 'Bakso sapi kenyal dengan kuah kaldu gurih dan mi.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Jenis Mi',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'mi kuning', 'harga' => 0],
                            ['nama' => 'bihun', 'harga' => 0],
                            ['nama' => 'tanpa mi', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Level Pedas',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'biasa', 'harga' => 0],
                            ['nama' => 'pedas', 'harga' => 0],
                        ]
                    ],
                ],
            ],
            [
                'nama_item'       => 'Jus Alpukat',
                'kategori'        => 'Minuman',
                'harga'           => 10000,
                'status_stok'     => true,
                'deskripsi'       => 'Jus alpukat segar dengan susu kental manis.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Gula',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'normal', 'harga' => 0],
                            ['nama' => 'kurang manis', 'harga' => 0],
                            ['nama' => 'tanpa gula', 'harga' => 0],
                        ]
                    ],
                ],
            ],
            [
                'nama_item'       => 'Kopi Susu Segar',
                'kategori'        => 'Minuman',
                'harga'           => 8000,
                'status_stok'     => true,
                'deskripsi'       => 'Kopi robusta Semarang dengan susu segar, disajikan dingin.',
                'estimasi_waktu'  => 4,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Suhu',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'es', 'harga' => 0],
                            ['nama' => 'panas', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Ukuran',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'regular', 'harga' => 0],
                            ['nama' => 'large', 'harga' => 3000],
                        ]
                    ],
                ],
            ],
        ];

        foreach ($menuKantin2 as $item) {
            Menu::create(array_merge(['kantin_id' => $kantin2->id], $item));
        }

        // ── Kantin 3: Kantin GKT (Gedung Kuliah Terpadu) ────────────────
        $kantin3 = $kantinList[2];

        $menuKantin3 = [
            [
                'nama_item'       => 'Ayam Geprek',
                'kategori'        => 'Makanan',
                'harga'           => 17000,
                'status_stok'     => true,
                'deskripsi'       => 'Ayam goreng crispy digeprek dengan sambal bawang, menu andalan anak Polines.',
                'estimasi_waktu'  => 12,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus', 'pengantaran'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Level Pedas',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'level 1', 'harga' => 0],
                            ['nama' => 'level 2', 'harga' => 0],
                            ['nama' => 'level 3', 'harga' => 0],
                            ['nama' => 'level 4', 'harga' => 0],
                            ['nama' => 'level 5', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Bagian Ayam',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'dada', 'harga' => 0],
                            ['nama' => 'paha', 'harga' => 0],
                            ['nama' => 'sayap', 'harga' => 0],
                        ]
                    ],
                ],
            ],
            [
                'nama_item'       => 'Nasi Kotak Lauk 3',
                'kategori'        => 'Makanan',
                'harga'           => 20000,
                'status_stok'     => true,
                'deskripsi'       => 'Nasi dengan 3 pilihan lauk + sayur + sambal, praktis untuk mahasiswa sibuk.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['dibungkus', 'pengantaran'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Lauk 1',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'ayam goreng', 'harga' => 0],
                            ['nama' => 'ayam balado', 'harga' => 0],
                            ['nama' => 'ayam bakar', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Lauk 2',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'tempe orek', 'harga' => 0],
                            ['nama' => 'tahu balado', 'harga' => 0],
                            ['nama' => 'perkedel', 'harga' => 0],
                        ]
                    ],
                    [
                        'nama' => 'Sayur',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'capcay', 'harga' => 0],
                            ['nama' => 'tumis kangkung', 'harga' => 0],
                            ['nama' => 'sayur asem', 'harga' => 0],
                        ]
                    ],
                ],
            ],
            [
                'nama_item'       => 'Es Jeruk Peras',
                'kategori'        => 'Minuman',
                'harga'           => 6000,
                'status_stok'     => true,
                'deskripsi'       => 'Jeruk segar diperas, manis dan segar untuk menemani kuliah.',
                'estimasi_waktu'  => 3,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => null,
                'varian'          => [
                    [
                        'nama' => 'Gula',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'manis', 'harga' => 0],
                            ['nama' => 'kurang manis', 'harga' => 0],
                            ['nama' => 'tanpa gula', 'harga' => 0],
                        ]
                    ],
                ],
            ],
        ];

        foreach ($menuKantin3 as $item) {
            Menu::create(array_merge(['kantin_id' => $kantin3->id], $item));
        }
    }
}