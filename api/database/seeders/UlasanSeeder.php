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
            ->with(['mahasiswa', 'kantin'])
            ->get();

        $ulasanData = [
            // Indeks 0: pesanan selesai pertama (Budi - Kantin Barokah, dine-in)
            [
                'rating'   => 5,
                'komentar' => 'Nasi gorengnya enak banget, porsi besar dan harga terjangkau! Es tehnya juga segar. Pasti balik lagi!',
            ],
            // Indeks 1: pesanan selesai kedua (Siti - Warung Bu Sri, take-away)
            [
                'rating'   => 4,
                'komentar' => 'Pecel-nya enak, bumbu kacangnya pas. Kopi susu segar-nya mantap. Tapi antrian lumayan lama.',
            ],
            // Indeks 2: pesanan selesai ketiga (Rizky - Kantin Pak Agus, delivery)
            [
                'rating'   => 4,
                'komentar' => 'Nasi kotaknya enak dan dikemas rapi. Pengirimannya cepat juga. Tapi es jeruknya kurang manis dikit.',
            ],
        ];

        foreach ($pesananSelesai as $index => $pesanan) {
            // Gunakan ulasan sesuai urutan, atau ulasan default jika melebihi array
            $data = $ulasanData[$index] ?? [
                'rating'   => rand(3, 5),
                'komentar' => 'Pelayanan memuaskan, akan pesan lagi.',
            ];

            // CARI MENU ID UNTUK SEEDER:
            // Ambil secara acak satu menu yang kebetulan dijual oleh kantin tersebut
            $menu_id = \App\Models\Menu::where('kantin_id', $pesanan->kantin_id)
                                       ->inRandomOrder()
                                       ->value('id');

            Ulasan::create([
                'pesanan_id'   => $pesanan->id,
                'mahasiswa_id' => $pesanan->mahasiswa_id,
                'kantin_id'    => $pesanan->kantin_id,
                'menu_id'      => $menu_id, // <-- Ganti $request->menu_id dengan variabel ini
                'rating'       => $data['rating'],
                'komentar'     => $data['komentar'],
            ]);
        }
    }
}
