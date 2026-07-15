<?php

namespace Database\Seeders;

use App\Models\Pesanan;
use App\Models\Ulasan;
use Illuminate\Database\Seeder;

class UlasanSeeder extends Seeder
{
    public function run(): void
    {
        // Ambil semua pesanan yang sudah selesai dan belum punya ulasan, kecuali yang ditandai belum dirating
        $pesananSelesai = Pesanan::where('status_pesanan', 'selesai')
            ->whereDoesntHave('ulasan')
            ->where(function($query) {
                $query->whereNull('catatan_pesanan')
                      ->orWhere('catatan_pesanan', 'not like', '%belum dirating%');
            })
            ->with(['mahasiswa', 'kantin', 'details'])
            ->get();

        $ulasanData = [
            // Indeks 0: pesanan selesai pertama
            [
                'rating'   => 5,
                'komentar' => 'Nasi gorengnya enak banget, porsi besar dan harga terjangkau! Es tehnya juga segar. Pasti balik lagi ke Kantek!',
            ],
            // Indeks 1: pesanan selesai kedua
            [
                'rating'   => 4,
                'komentar' => 'Bakso kuahnya mantap, kuahnya gurih. Delivery ke Perpustakaan Polines juga cepat. Top!',
            ],
            // Indeks 2: pesanan selesai ketiga
            [
                'rating'   => 4,
                'komentar' => 'Nasi kotaknya enak dan dikemas rapi. Pengirimannya cepat juga. Tapi es jeruknya kurang manis dikit.',
            ],
        ];

        foreach ($pesananSelesai as $index => $pesanan) {
            // Gunakan ulasan sesuai urutan, atau ulasan default jika melebihi array
            $data = $ulasanData[$index] ?? [
                'rating'   => rand(3, 5),
                'komentar' => 'Pelayanan di kantin Polines memuaskan, akan pesan lagi.',
            ];

            // Ambil menu_id dari pesanan detail yang terkait
            $menuId = $pesanan->details->first()?->menu_id;
            
            // Fallback: ambil menu acak dari kantin jika tidak ada detail
            if (!$menuId) {
                $menuId = \App\Models\Menu::where('kantin_id', $pesanan->kantin_id)
                    ->inRandomOrder()
                    ->value('id');
            }

            if (!$menuId) continue;

            Ulasan::create([
                'pesanan_id'   => $pesanan->id,
                'mahasiswa_id' => $pesanan->mahasiswa_id,
                'kantin_id'    => $pesanan->kantin_id,
                'menu_id'      => $menuId,
                'rating'       => $data['rating'],
                'komentar'     => $data['komentar'],
            ]);
        }
    }
}
