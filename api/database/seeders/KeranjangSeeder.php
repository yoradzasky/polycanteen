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
        if ($mahasiswaList->count() < 5) return;

        // ── Budi: punya item di keranjang Kantin Teknik ──────────────────
        $budi = $mahasiswaList[0];
        $menuKantek = Menu::whereHas('kantin', fn($q) => $q->where('nama_kantin', 'Kantin Teknik (Kantek)'))
            ->orderBy('id')
            ->get();

        if ($menuKantek->count() >= 3) {
            Keranjang::create([
                'mahasiswa_id'    => $budi->id,
                'menu_id'         => $menuKantek[0]->id, // Nasi Goreng Spesial
                'jumlah'          => 1,
                'varian_selected' => ['Level Pedas' => ['nama' => 'pedas', 'harga' => 0]],
            ]);

            Keranjang::create([
                'mahasiswa_id'    => $budi->id,
                'menu_id'         => $menuKantek[2]->id, // Es Teh Manis
                'jumlah'          => 2,
                'varian_selected' => ['Suhu' => ['nama' => 'es', 'harga' => 0]],
            ]);
        }

        // ── Siti: punya item di keranjang Kantin TN ──────────────────────
        $siti = $mahasiswaList[1];
        $menuTN = Menu::whereHas('kantin', fn($q) => $q->where('nama_kantin', 'Kantin Tata Niaga (TN)'))
            ->orderBy('id')
            ->get();

        if ($menuTN->count() >= 4) {
            Keranjang::create([
                'mahasiswa_id'    => $siti->id,
                'menu_id'         => $menuTN[1]->id, // Bakso Kuah
                'jumlah'          => 1,
                'varian_selected' => [
                    'Jenis Mi'    => ['nama' => 'mi kuning', 'harga' => 0], 
                    'Level Pedas' => ['nama' => 'pedas', 'harga' => 0]
                ],
            ]);

            Keranjang::create([
                'mahasiswa_id'    => $siti->id,
                'menu_id'         => $menuTN[3]->id, // Kopi Susu Segar
                'jumlah'          => 1,
                'varian_selected' => [
                    'Suhu'   => ['nama' => 'es', 'harga' => 0], 
                    'Ukuran' => ['nama' => 'large', 'harga' => 3000]
                ],
            ]);
        }

        // ── Andi: keranjang di Kantin GKT ────────────────────────────────
        $andi = $mahasiswaList[2];
        $menuGKT = Menu::whereHas('kantin', fn($q) => $q->where('nama_kantin', 'Kantin GKT (Gedung Kuliah Terpadu)'))
            ->orderBy('id')
            ->get();

        if ($menuGKT->count() >= 1) {
            Keranjang::create([
                'mahasiswa_id'    => $andi->id,
                'menu_id'         => $menuGKT[0]->id, // Ayam Geprek
                'jumlah'          => 2,
                'varian_selected' => [
                    'Level Pedas' => ['nama' => 'level 4', 'harga' => 0], 
                    'Bagian Ayam' => ['nama' => 'sayap', 'harga' => 0]
                ],
            ]);
        }

        // ── Rizky: 1 item di keranjang Kantin TN ─────────────────────────
        $rizky = $mahasiswaList[4];
        if ($menuTN->count() >= 1) {
            Keranjang::create([
                'mahasiswa_id'    => $rizky->id,
                'menu_id'         => $menuTN[0]->id, // Pecel Komplit
                'jumlah'          => 1,
                'varian_selected' => ['Nasi' => ['nama' => 'nasi putih', 'harga' => 0]],
            ]);
        }
    }
}