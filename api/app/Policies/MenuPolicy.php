<?php

namespace App\Policies;

use App\Models\User;

class MenuPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['pemilik', 'pegawai']);
    }

    /**
     * Determine whether the user can manage (create, update, delete, toggle) menus.
     */
    public function manage(User $user): bool
    {
        return $user->role === 'pemilik';
    }

    /**
     * Determine whether the user can toggle the stock status.
     */
    public function updateStatus(User $user): bool
    {
        return in_array($user->role, ['pemilik', 'pegawai']);
    }
}
