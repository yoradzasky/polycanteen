<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Pesanan extends Model
{
    protected $table = 'pesanan';
    protected $fillable = [
        'mahasiswa_id',
        'kantin_id',
        'tipe_pesanan',
        'status_pesanan',
        'total_harga'
    ];

    public function mahasiswa(): BelongsTo
    {
        return $this->belongsTo(Mahasiswa::class);
    }

    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class);
    }

    public function details(): HasMany
    {
        return $this->hasMany(PesananDetail::class);
    }

    public function payment(): HasOne
    {
        return $this->hasOne(Payment::class);
    }
}
