<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Kantin extends Model
{
    use SoftDeletes;
    protected $table = 'kantin';

    protected $fillable = [
        'nama_kantin',
        'lokasi_lengkap',
        'longitude',
        'latitude',
        'status_toko',
        'logo_path'
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
    ];
    public function pemilik(): HasOne
    {
        return $this->hasOne(Pemilik::class, 'kantin_id', 'id');
    }

    public function menus(): HasMany
    {
        return $this->hasMany(Menu::class);
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'kantin_id');
    }

    public function pegawai(): HasMany
    {
        return $this->hasMany(Pegawai::class, 'kantin_id', 'id');
    }
}