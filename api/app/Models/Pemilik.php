<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Pemilik extends Model
{
    protected $table = 'pemilik';
    // kantin_id ditambahkan sesuai ERD baru
    protected $fillable = ['user_id', 'kantin_id', 'nama_pemilik', 'no_telp'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Relasi ke Kantin
    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class, 'kantin_id', 'id');
    }
}