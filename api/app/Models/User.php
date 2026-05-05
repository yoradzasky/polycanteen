<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\HasOne;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'username',
        'email',
        'password',
        'role', // admin, mahasiswa, kantin, kurir
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    // Relasi ke profil mahasiswa
    public function mahasiswa(): HasOne
    {
        return $this->hasOne(Mahasiswa::class);
    }

    // Relasi ke profil pemilik kantin
    public function pemilik(): HasOne
    {
        return $this->hasOne(Pemilik::class);
    }
    
    // Relasi ke kantin yang dikelola (untuk role 'kantin')
    public function kantin(): HasOne
    {
        return $this->hasOne(Kantin::class);
    }
}   