<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Pesanan;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Buat 1 Akun Admin Utama
        User::create([
            'username' => 'Admin Utama',
            'email' => 'admin@kantin.com',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'status_akun' => 'aktif',
        ]);

        // 2. Buat 16 Data Kantin
        for ($i = 0; $i < 16; $i++) {
            // Kita tetap buatkan user kantinnya untuk keperluan login nanti
            User::create([
                'username' => 'User Kantin ' . ($i + 1),
                'email' => 'kantin' . ($i + 1) . '@polycanteen.com',
                'password' => Hash::make('password123'),
                'role' => 'kantin',
                'status_akun' => 'aktif',
            ]);

            // Masukkan data ke tabel 'kantin' sesuai struktur migration-mu
            DB::table('kantin')->insert([
                'nama_kantin' => $kantinNama[$i],
                'status_toko' => 'buka', // Set otomatis buka
                'created_at' => now()->subDays(rand(30, 180)),
                'updated_at' => now(),
            ]);
        }

        // 3. Buat 100+ Akun Mahasiswa
        for ($i = 0; $i < count($namaMahasiswa); $i++) {
            // Generate avatar URL dari UI Avatars
            $avatarUrl = 'https://ui-avatars.com/api/?name=' . urlencode($namaMahasiswa[$i]) . '&background=random&color=fff&size=200';
            
            $userMhs = User::create([
                'username' => strtolower(str_replace(' ', '.', $namaMahasiswa[$i])),
                'email' => strtolower(str_replace(' ', '.', $namaMahasiswa[$i])) . '@student.ac.id',
                'password' => Hash::make('password123'),
                'role' => 'mahasiswa',
                'status_akun' => 'aktif',
                'foto_profile' => $avatarUrl,
            ]);

            // Masukkan data ke tabel 'mahasiswa'
            DB::table('mahasiswa')->insert([
                'user_id' => $userMhs->id,
                'nama_mahasiswa' => $namaMahasiswa[$i], 
                'nim' => '3202' . str_pad($i + 1, 4, '0', STR_PAD_LEFT), 
                'created_at' => now()->subDays(rand(5, 180)),
                'updated_at' => now(),
            ]);
        }

        // 4. Buat 200+ Data Pesanan dengan distribusi status yang lebih realistis
        $tipe = ['makan_ditempat', 'dibungkus'];
        $status = ['selesai', 'selesai', 'selesai', 'selesai', 'diproses', 'ditolak'];
        
        for ($i = 1; $i <= 250; $i++) {
            $statusRandom = $status[array_rand($status)];
            $hargaRandom = rand(15, 100) * 1000; 

            // Ambil ID mahasiswa dan kantin secara acak
            $randomMahasiswaId = rand(1, 60);
            $randomKantinId = rand(1, 16);

            // Buat tanggal yang bervariasi (0-45 hari lalu untuk aktivitas terbaru)
            $daysAgo = rand(0, 45);
            $createdDate = now()->subDays($daysAgo)->setHour(rand(6, 20))->setMinute(rand(0, 59));

            // Insert ke tabel pesanan
            DB::table('pesanan')->insert([
                'mahasiswa_id' => $randomMahasiswaId, 
                'kantin_id' => $randomKantinId,      
                'tipe_pesanan' => $tipe[array_rand($tipe)],
                'status_pesanan' => $statusRandom,
                'total_harga' => $hargaRandom,
                'created_at' => $createdDate, 
                'updated_at' => $createdDate,
            ]);
        }
    }
}