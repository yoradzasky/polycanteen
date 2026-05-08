<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kantin extends Model
{
    protected $table = 'kantin';
    // user_id diganti menjadi pemilik_id sesuai ERD
    protected $fillable = ['pemilik_id', 'nama_kantin', 'longitude', 'latitude', 'status_toko', 'logo_path'];

    // Relasinya sekarang menunjuk ke Pemilik, bukan User
    public function owner(): BelongsTo
    {
        return $this->belongsTo(Pemilik::class, 'pemilik_id');
    }

    public function menus(): HasMany
    {
        return $this->hasMany(Menu::class);
    }

    // Menambahkan relasi ke Pegawai (karena nama tabelnya ganti di ERD)
    public function pegawai(): HasMany
    {
        return $this->hasMany(Pegawai::class);
    }
}