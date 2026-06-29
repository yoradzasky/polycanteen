<?php

namespace App\Services;

use App\Models\User;

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

        return $user;
    }
}