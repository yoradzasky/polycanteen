<?php

namespace App\Services;

use App\Models\User;
use App\Models\Kantin; // 

class DashboardService
{
    /**
     * Mengambil rekap data untuk halaman Dashboard Admin
     */
    public function getDashboardStats()
    {
        return [
            // Menghitung user dengan role 'mahasiswa'
            'total_buyers' => User::where('role', 'mahasiswa')->count(),
            
            // Menghitung jumlah kantin yang terdaftar
            'total_canteens' => Kantin::count(),
            
            'total_revenue' => 0,  // Nanti kita isi saat tabel transaksi sudah ada
        ];
    }
}