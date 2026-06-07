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
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Level Pedas', 'pilihan' => ['tidak pedas', 'pedas', 'extra pedas']],
                ],
                'topping'         => [
                    ['nama' => 'Telur Mata Sapi', 'harga' => 3000],
                    ['nama' => 'Sosis',           'harga' => 4000],
                    ['nama' => 'Kerupuk',         'harga' => 1000],
                ],
            ],
            [
                'nama_item'       => 'Mie Goreng Ayam',
                'kategori'        => 'Makanan',
                'harga'           => 13000,
                'status_stok'     => true,
                'deskripsi'       => 'Mie goreng dengan potongan ayam dan bumbu khas.',
                'estimasi_waktu'  => 8,
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Level Pedas', 'pilihan' => ['tidak pedas', 'pedas', 'extra pedas']],
                ],
                'topping'         => [
                    ['nama' => 'Telur Dadar', 'harga' => 3000],
                    ['nama' => 'Bakso',       'harga' => 5000],
                ],
            ],
            [
                'nama_item'       => 'Es Teh Manis',
                'kategori'        => 'Minuman',
                'harga'           => 5000,
                'status_stok'     => true,
                'deskripsi'       => 'Teh manis dingin yang menyegarkan.',
                'estimasi_waktu'  => 3,
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Suhu', 'pilihan' => ['es', 'panas']],
                ],
                'topping'         => null,
            ],
            [
                'nama_item'       => 'Soto Ayam',
                'kategori'        => 'Makanan',
                'harga'           => 14000,
                'status_stok'     => false, // contoh stok habis
                'deskripsi'       => 'Soto ayam kuah bening dengan pelengkap bihun, tauge, dan perkedel.',
                'estimasi_waktu'  => 7,
                'pilihan_layanan' => ['dine-in'],
                'varian'          => null,
                'topping'         => [
                    ['nama' => 'Tambah Nasi', 'harga' => 4000],
                    ['nama' => 'Kerupuk',     'harga' => 1000],
                ],
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
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Nasi', 'pilihan' => ['nasi putih', 'nasi uduk', 'tanpa nasi']],
                ],
                'topping'         => [
                    ['nama' => 'Tempe Goreng', 'harga' => 2000],
                    ['nama' => 'Tahu Goreng',  'harga' => 2000],
                    ['nama' => 'Rempeyek',     'harga' => 2000],
                ],
            ],
            [
                'nama_item'       => 'Bakso Kuah',
                'kategori'        => 'Makanan',
                'harga'           => 15000,
                'status_stok'     => true,
                'deskripsi'       => 'Bakso sapi kenyal dengan kuah kaldu gurih dan mi.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Jenis Mi', 'pilihan' => ['mi kuning', 'bihun', 'tanpa mi']],
                    ['nama' => 'Level Pedas', 'pilihan' => ['biasa', 'pedas']],
                ],
                'topping'         => [
                    ['nama' => 'Bakso Urat Ekstra', 'harga' => 5000],
                    ['nama' => 'Tahu Isi',          'harga' => 3000],
                ],
            ],
            [
                'nama_item'       => 'Jus Alpukat',
                'kategori'        => 'Minuman',
                'harga'           => 10000,
                'status_stok'     => true,
                'deskripsi'       => 'Jus alpukat segar dengan susu kental manis.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Gula', 'pilihan' => ['normal', 'kurang manis', 'tanpa gula']],
                ],
                'topping'         => null,
            ],
            [
                'nama_item'       => 'Kopi Susu Segar',
                'kategori'        => 'Minuman',
                'harga'           => 8000,
                'status_stok'     => true,
                'deskripsi'       => 'Kopi robusta dengan susu segar, disajikan dingin.',
                'estimasi_waktu'  => 4,
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Suhu',   'pilihan' => ['es', 'panas']],
                    ['nama' => 'Ukuran', 'pilihan' => ['regular', 'large']],
                ],
                'topping'         => [
                    ['nama' => 'Whipped Cream', 'harga' => 3000],
                    ['nama' => 'Ekstra Shot',   'harga' => 4000],
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
                'pilihan_layanan' => ['dine-in', 'take-away', 'delivery'],
                'varian'          => [
                    ['nama' => 'Level Pedas', 'pilihan' => ['level 1', 'level 2', 'level 3', 'level 4', 'level 5']],
                    ['nama' => 'Bagian Ayam', 'pilihan' => ['dada', 'paha', 'sayap']],
                ],
                'topping'         => [
                    ['nama' => 'Keju Slice',     'harga' => 5000],
                    ['nama' => 'Telor Ceplok',   'harga' => 3000],
                    ['nama' => 'Ekstra Sambal',  'harga' => 1000],
                ],
            ],
            [
                'nama_item'       => 'Nasi Kotak Lauk 3',
                'kategori'        => 'Makanan',
                'harga'           => 20000,
                'status_stok'     => true,
                'deskripsi'       => 'Nasi dengan 3 pilihan lauk (ayam/tempe/telur) + sayur + sambal.',
                'estimasi_waktu'  => 5,
                'pilihan_layanan' => ['take-away', 'delivery'],
                'varian'          => [
                    ['nama' => 'Lauk 1', 'pilihan' => ['ayam goreng', 'ayam balado', 'ayam bakar']],
                    ['nama' => 'Lauk 2', 'pilihan' => ['tempe orek', 'tahu balado', 'perkedel']],
                    ['nama' => 'Sayur',  'pilihan' => ['capcay', 'tumis kangkung', 'sayur asem']],
                ],
                'topping'         => null,
            ],
            [
                'nama_item'       => 'Es Jeruk Peras',
                'kategori'        => 'Minuman',
                'harga'           => 6000,
                'status_stok'     => true,
                'deskripsi'       => 'Jeruk segar diperas, manis dan segar.',
                'estimasi_waktu'  => 3,
                'pilihan_layanan' => ['dine-in', 'take-away'],
                'varian'          => [
                    ['nama' => 'Gula', 'pilihan' => ['manis', 'kurang manis', 'tanpa gula']],
                ],
                'topping'         => null,
            ],
        ];

        foreach ($menuKantin3 as $item) {
            Menu::create(array_merge(['kantin_id' => $kantin3->id], $item));
        }
    }
}
