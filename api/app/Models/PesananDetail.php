<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
// use Illuminate\Database\Eloquent\Relations\HasOne; // <-- Dihapus karena tidak dipakai lagi

class PesananDetail extends Model
{
    protected $table = 'pesanan_detail';
    
    protected $fillable = [
        'pesanan_id',
        'menu_id',
        'harga_saat_beli',
        'jumlah_pesanan',
        'subtotal',
        'varian_snapshot',
    ];

    protected $casts = [
        'varian_snapshot' => 'array',
    ];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class);
    }

    /**
     * Diperbaiki menjadi BelongsTo karena tabel pesanan_detail 
     * yang menyimpan kolom menu_id.
     */
    public function menu(): BelongsTo
    {
        return $this->belongsTo(Menu::class);
    }
}