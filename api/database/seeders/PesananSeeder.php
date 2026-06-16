<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\Mahasiswa;
use App\Models\Kantin;
use App\Models\Menu;
use App\Models\Payment;
use App\Models\Ulasan;
use Faker\Factory as Faker;

class PesananSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $faker = Faker::create('id_ID');
        $mahasiswas = Mahasiswa::all();
        $kantins = Kantin::with('menus')->get();

        if ($mahasiswas->isEmpty() || $kantins->isEmpty()) {
            $this->command->info('Mahasiswa or Kantin not found. Please run DatabaseSeeder first.');
            return;
        }

        // Generate 50 additional orders
        for ($i = 0; $i < 50; $i++) {
            $mahasiswa = $mahasiswas->random();
            $kantin = $kantins->random();
            
            if ($kantin->menus->isEmpty()) continue;
            
            $numItems = rand(1, 3);
            $selectedMenus = $kantin->menus->random(min($numItems, $kantin->menus->count()));
            
            $totalHarga = 0;
            $pesananDetails = [];

            foreach ($selectedMenus as $menu) {
                $jumlah = rand(1, 2);
                $subtotal = $menu->harga * $jumlah;
                $totalHarga += $subtotal;

                $pesananDetails[] = [
                    'menu_id' => $menu->id,
                    'harga_saat_beli' => $menu->harga,
                    'jumlah_pesanan' => $jumlah,
                    'subtotal' => $subtotal,
                    'varian_snapshot' => null,
                    'topping_snapshot' => null,
                ];
            }

            $pesanan = Pesanan::create([
                'mahasiswa_id' => $mahasiswa->id,
                'kantin_id' => $kantin->id,
                'tipe_pesanan' => $faker->randomElement(['dine_in', 'take_away']),
                'status_pesanan' => $faker->randomElement(['pending', 'dibayar', 'dimasak', 'dalam_perjalanan', 'selesai', 'ditolak']),
                'total_harga' => $totalHarga,
                'nomor_antrian' => 'A-' . str_pad(rand(1, 999), 3, '0', STR_PAD_LEFT),
                'catatan_pesanan' => $faker->optional()->sentence,
            ]);

            foreach ($pesananDetails as $detail) {
                $detail['pesanan_id'] = $pesanan->id;
                PesananDetail::create($detail);
            }

            // Randomly create payment for 'dibayar' or 'selesai' status
            if (in_array($pesanan->status_pesanan, ['dibayar', 'dimasak', 'dalam_perjalanan', 'selesai'])) {
                Payment::create([
                    'pesanan_id' => $pesanan->id,
                    'metode_bayar' => $faker->randomElement(['qris', 'va']),
                    'status_bayar' => 'sukses',
                    'log_transaksi' => json_encode(['transaction_status' => 'settlement']),
                    'nominal' => $totalHarga,
                    'waktu_bayar' => now()->subMinutes(rand(10, 1000)),
                    'midtrans_order_id' => $pesanan->id . '-' . time(),
                    'midtrans_snap_token' => 'token_' . $faker->bothify('??##??##'),
                ]);
            }

            // Randomly create ulasan for 'selesai' status
            if ($pesanan->status_pesanan === 'selesai' && rand(0, 1)) {
                Ulasan::create([
                    'pesanan_id' => $pesanan->id,
                    'mahasiswa_id' => $mahasiswa->id,
                    'kantin_id' => $kantin->id,
                    'rating' => rand(3, 5),
                    'komentar' => $faker->sentence,
                ]);
            }
        }

        $this->command->info('Successfully seeded 50 orders.');
    }
}
