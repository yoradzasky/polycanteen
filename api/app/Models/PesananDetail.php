<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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
        'topping_snapshot',
    ];

    protected $casts = [
        'varian_snapshot' => 'array',
        'topping_snapshot' => 'array',
    ];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class);
    }

    public function menu(): BelongsTo
    {
        return $this->belongsTo(Menu::class);
    }
}
