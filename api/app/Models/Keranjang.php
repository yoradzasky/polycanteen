<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Keranjang extends Model
{
    protected $table = 'keranjang';
    protected $fillable = [
        'mahasiswa_id',
        'menu_id',
        'kantin_id',
        'jumlah',
        'varian_selected',
        'topping_selected',
    ];

    protected $casts = [
        'varian_selected' => 'array',
        'topping_selected' => 'array',
    ];

    // RELASI KE MAHASISWA
    public function mahasiswa(): BelongsTo
    {
        return $this->belongsTo(Mahasiswa::class);
    }

    // RELASI KE MENU
    public function menu(): BelongsTo
    {
        return $this->belongsTo(Menu::class);
    }

    // RELASI KE KANTIN
    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class);
    }
}
