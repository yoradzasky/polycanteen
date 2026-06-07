<?php

namespace Database\Seeders;

use App\Models\Keranjang;
use App\Models\Mahasiswa;
use App\Models\Menu;
use Illuminate\Database\Seeder;

class KeranjangSeeder extends Seeder
{
    public function run(): void
    {
        $mahasiswaList = Mahasiswa::orderBy('id')->get();

        // ── Budi: punya item di keranjang Kantin Barokah ─────────────────
        $budi        = $mahasiswaList[0];
        $menuBarokah = Menu::whereHas('kantin', fn($q) => $q->where('nama_kantin', 'Kantin Barokah'))
            ->orderBy('id')
            ->get();

        if ($menuBarokah->count() >= 2) {
            Keranjang::create([
                'mahasiswa_id'    => $budi->id,
                'menu_id'         => $menuBarokah[0]->id, // Nasi Goreng Spesial
                'jumlah'          => 1,
                'varian_selected' => ['Level Pedas' => 'pedas'],
                'topping_selected'=> [['nama' => 'Telur Mata Sapi', 'harga' => 3000]],
            ]);

            Keranjang::create([
                'mahasiswa_id'    => $budi->id,
                'menu_id'         => $menuBarokah[2]->id, // Es Teh Manis
                'jumlah'          => 2,
                'varian_selected' => ['Suhu' => 'es'],
                'topping_selected'=> null,
            ]);
        }

        // ── Siti: punya item di keranjang Warung Bu Sri ───────────────────
        $siti     = $mahasiswaList[1];
        $menuSri  = Menu::whereHas('kantin', fn($q) => $q->where('nama_kantin', 'Warung Bu Sri'))
            ->orderBy('id')
            ->get();

        if ($menuSri->count() >= 2) {
            Keranjang::create([
                'mahasiswa_id'    => $siti->id,
                'menu_id'         => $menuSri[1]->id, // Bakso Kuah
                'jumlah'          => 1,
                'varian_selected' => ['Jenis Mi' => 'mi kuning', 'Level Pedas' => 'pedas'],
                'topping_selected'=> [['nama' => 'Bakso Urat Ekstra', 'harga' => 5000]],
            ]);

            Keranjang::create([
                'mahasiswa_id'    => $siti->id,
                'menu_id'         => $menuSri[3]->id, // Kopi Susu Segar
                'jumlah'          => 1,
                'varian_selected' => ['Suhu' => 'es', 'Ukuran' => 'large'],
                'topping_selected'=> [['nama' => 'Whipped Cream', 'harga' => 3000]],
            ]);
        }

        // ── Andi: keranjang di Kantin Pak Agus ───────────────────────────
        $andi      = $mahasiswaList[2];
        $menuAgus  = Menu::whereHas('kantin', fn($q) => $q->where('nama_kantin', 'Kantin Pak Agus'))
            ->orderBy('id')
            ->get();

        if ($menuAgus->count() >= 1) {
            Keranjang::create([
                'mahasiswa_id'    => $andi->id,
                'menu_id'         => $menuAgus[0]->id, // Ayam Geprek
                'jumlah'          => 2,
                'varian_selected' => ['Level Pedas' => 'level 4', 'Bagian Ayam' => 'sayap'],
                'topping_selected'=> [
                    ['nama' => 'Telor Ceplok',  'harga' => 3000],
                    ['nama' => 'Ekstra Sambal',  'harga' => 1000],
                ],
            ]);
        }

        // ── Dewi: keranjang kosong (tidak ada item) — tidak di-seed ──────
        // ── Rizky: 1 item di keranjang Warung Bu Sri ─────────────────────
        $rizky = $mahasiswaList[4];

        if ($menuSri->count() >= 1) {
            Keranjang::create([
                'mahasiswa_id'    => $rizky->id,
                'menu_id'         => $menuSri[0]->id, // Pecel Komplit
                'jumlah'          => 1,
                'varian_selected' => ['Nasi' => 'nasi putih'],
                'topping_selected'=> [
                    ['nama' => 'Tempe Goreng', 'harga' => 2000],
                    ['nama' => 'Rempeyek',     'harga' => 2000],
                ],
            ]);
        }
    }
}
