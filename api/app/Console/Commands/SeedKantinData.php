<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Kantin;
use App\Models\Pemilik;
use App\Models\Menu;

class SeedKantinData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:seed-kantin-data';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Menambahkan data dummy untuk User, Kantin, Pemilik, dan Menu secara berurutan';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Memulai proses insert data...');

        DB::beginTransaction();

        try {
            // 1. Buat User (Pemilik)
            $user = User::create([
                'username' => 'pemilik_budi',
                'email' => 'budi@kantin.com',
                'password' => Hash::make('password123'),
                'status_akun' => 'aktif',
                'role' => 'pemilik',
            ]);
            $this->info("User '{$user->username}' berhasil dibuat.");

            // 2. Buat Kantin
            $kantin = Kantin::create([
                'nama_kantin' => 'Kantin Budi Sejahtera',
                'lokasi_lengkap' => 'Gedung A, Lantai 1',
                'longitude' => 106.827153, // Contoh longitude
                'latitude' => -6.175110,  // Contoh latitude
                'status_toko' => 'buka',
                'logo_path' => null,
            ]);
            $this->info("Kantin '{$kantin->nama_kantin}' berhasil dibuat.");

            // 3. Buat Pemilik (Menghubungkan User dan Kantin)
            $pemilik = Pemilik::create([
                'user_id' => $user->id,
                'kantin_id' => $kantin->id,
                'nama_pemilik' => 'Budi Santoso',
                'no_telp' => '081234567890',
            ]);
            $this->info("Data Pemilik '{$pemilik->nama_pemilik}' berhasil disambungkan.");

            // 4. Buat Menu untuk Kantin tersebut
            $menus = [
                [
                    'kantin_id' => $kantin->id,
                    'nama_item' => 'Nasi Goreng Spesial',
                    'kategori' => 'Makanan',
                    'harga' => 20000,
                    'foto_menu' => null,
                    'status_stok' => '1',
                ],
                [
                    'kantin_id' => $kantin->id,
                    'nama_item' => 'Es Teh Manis',
                    'kategori' => 'Minuman',
                    'harga' => 5000,
                    'foto_menu' => null,
                    'status_stok' => '1',
                ]
            ];

            foreach ($menus as $menuData) {
                Menu::create($menuData);
            }
            $this->info("Data Menu berhasil ditambahkan ke kantin.");

            DB::commit();
            $this->info('Semua data berhasil di-generate secara sukses!');

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('Terjadi kesalahan saat menambahkan data: ' . $e->getMessage());
        }
    }
}