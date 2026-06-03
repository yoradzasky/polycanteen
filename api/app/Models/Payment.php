<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    protected $table = 'payment';
    protected $fillable = [
        'pesanan_id', 'metode_bayar', 'status_bayar', 'log_transaksi',
        'nominal', 'waktu_bayar', 'midtrans_order_id', 'midtrans_snap_token',
    ];

    protected $casts = [
        'waktu_bayar' => 'datetime',
    ];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class);
    }
}
