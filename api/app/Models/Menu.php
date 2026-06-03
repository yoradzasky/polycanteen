<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Menu extends Model
{
    protected $table = 'menu';
    protected $fillable = [
        'kantin_id', 'nama_item', 'kategori', 'harga', 'foto_menu', 'status_stok',
        'deskripsi', 'estimasi_waktu', 'pilihan_layanan', 'varian', 'topping',
    ];

    protected $casts = [
        'status_stok' => 'boolean',
        'pilihan_layanan' => 'array',
        'varian' => 'array',
        'topping' => 'array',
    ];

    protected $appends = ['status_stok_label'];

    /**
     * Accessor: konversi boolean status_stok ke label string
     */
    public function getStatusStokLabelAttribute(): string
    {
        return $this->status_stok ? 'tersedia' : 'habis';
    }

    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class);
    }

    public function pesananDetails(): HasMany
    {
        return $this->hasMany(PesananDetail::class, 'menu_id');
    }

    public function keranjang(): HasMany
    {
        return $this->hasMany(Keranjang::class);
    }
}
