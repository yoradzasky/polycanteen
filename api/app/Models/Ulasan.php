<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Ulasan extends Model
{
    protected $table = 'ulasan';

    protected $fillable = [
        'pesanan_id',
        'mahasiswa_id',
        'kantin_id',
        'rating',
        'komentar',
    ];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class);
    }

    public function mahasiswa(): BelongsTo
    {
        return $this->belongsTo(Mahasiswa::class);
    }

    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class);
    }
}
