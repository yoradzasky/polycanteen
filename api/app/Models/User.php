<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasOneThrough;

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

    public function mahasiswa(): HasOne
    {
        return $this->hasOne(Mahasiswa::class);
    }

    public function pemilik(): HasOne
    {
        return $this->hasOne(Pemilik::class);
    }
    
    // Diupdate menggunakan HasOneThrough karena harus melewati model Pemilik
    public function kantin(): HasOneThrough
    {
        return $this->hasOneThrough(Kantin::class, Pemilik::class, 'user_id', 'pemilik_id', 'id', 'id');
    }
}