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

        // ── Kantin 1: Kantin Barokah ─────────────────────────────────────
        $kantin1 = $kantinList[0];

        $menuKantin1 = [
            [
                'nama_item'       => 'Nasi Goreng Spesial',
                'kategori'        => 'Makanan',
                'harga'           => 15000,
                'status_stok'     => true,
                'deskripsi'       => 'Nasi goreng dengan telur, ayam, dan sayuran segar pilihan.',
                'estimasi_waktu'  => 10,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1603133872878-685f2026d5f5?w=500&auto=format&fit=crop',
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
                'foto_menu'       => 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=500&auto=format&fit=crop',
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
                'deskripsi'       => 'Teh manis dingin yang menyegarkan.',
                'estimasi_waktu'  => 3,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop',
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
                'nama_item'       => 'Soto Ayam',
                'kategori'        => 'Makanan',
                'harga'           => 14000,
                'status_stok'     => false, // contoh stok habis
                'deskripsi'       => 'Soto ayam kuah bening dengan pelengkap bihun, tauge, dan perkedel.',
                'estimasi_waktu'  => 7,
                'pilihan_layanan' => ['makan_di_tempat'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1626804475315-77626996d911?w=500&auto=format&fit=crop',
                'varian'          => null,
            ],
        ];

        foreach ($menuKantin1 as $item) {
            Menu::create(array_merge(['kantin_id' => $kantin1->id], $item));
        }

        // ── Kantin 2: Warung Bu Sri ──────────────────────────────────────
        $kantin2 = $kantinList[1];

        $menuKantin2 = [
            [
                'nama_item'       => 'Pecel Komplit',
                'kategori'        => 'Makanan',
                'harga'           => 12000,
                'status_stok'     => true,
                'deskripsi'       => 'Pecel dengan sayuran rebus segar dan bumbu kacang khas.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1590137876181-2a5a7e340308?w=500&auto=format&fit=crop',
                'varian'          => [
                    [
                        'nama' => 'Nasi',
                        'tipe' => 'wajib',
                        'pilihan' => [
                            ['nama' => 'nasi putih', 'harga' => 0],
                            ['nama' => 'nasi uduk', 'harga' => 2000], // harga beda untuk uduk
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
                'foto_menu'       => 'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?w=500&auto=format&fit=crop',
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
                'foto_menu'       => 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&auto=format&fit=crop',
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
                'deskripsi'       => 'Kopi robusta dengan susu segar, disajikan dingin.',
                'estimasi_waktu'  => 4,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500&auto=format&fit=crop',
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
                            ['nama' => 'large', 'harga' => 3000], // Large +3000
                        ]
                    ],
                ],
            ],
        ];

        foreach ($menuKantin2 as $item) {
            Menu::create(array_merge(['kantin_id' => $kantin2->id], $item));
        }

        // ── Kantin 3: Kantin Pak Agus ────────────────────────────────────
        $kantin3 = $kantinList[2];

        $menuKantin3 = [
            [
                'nama_item'       => 'Ayam Geprek',
                'kategori'        => 'Makanan',
                'harga'           => 17000,
                'status_stok'     => true,
                'deskripsi'       => 'Ayam goreng crispy digeprek dengan sambal bawang.',
                'estimasi_waktu'  => 12,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus', 'pengantaran'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1626240906144-48615b161f3d?w=500&auto=format&fit=crop',
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
                'deskripsi'       => 'Nasi dengan 3 pilihan lauk + sayur + sambal.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['dibungkus', 'pengantaran'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop',
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
                'deskripsi'       => 'Jeruk segar diperas, manis dan segar.',
                'estimasi_waktu'  => 3,
                'pilihan_layanan' => ['makan_di_tempat', 'dibungkus'],
                'foto_menu'       => 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=500&auto=format&fit=crop',
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