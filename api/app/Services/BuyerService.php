<?php

namespace App\Services;

use App\Models\User;
use Carbon\Carbon;

class BuyerService
{
    /**
     * Memperbarui masa_aktif mahasiswa di MySQL.
     */
    public function updateActiveUntil($userId, $newDate)
    {
        $user = User::with('mahasiswa')->findOrFail($userId);
        
        if ($user->mahasiswa) {
            // Mengubah data pada kolom masa_aktif
            $user->mahasiswa->masa_aktif = $newDate;
            $user->mahasiswa->save();
        }

        // Sesuaikan status_akun berdasarkan tanggal
        if (empty($newDate)) {
            $user->status_akun = 'aktif';
        } else {
            $parsedDate = Carbon::parse($newDate)->startOfDay();
            $today = Carbon::now()->startOfDay();
            
            if ($parsedDate->lessThanOrEqualTo($today)) {
                $user->status_akun = 'nonaktif';
            } else {
                $user->status_akun = 'aktif';
            }
        }
        $user->save();

        return $user;
    }
}