<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Tracking extends Model
{
    protected $table = 'tracking';
    protected $fillable = ['pesanan_id', 'user_id', 'lokasi_pembeli', 'lokasi_pegawai'];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class);
    }

    // Merujuk ke kurir (User) yang bertugas
    public function kurir(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}