<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pemilik extends Model
{
    protected $table = 'pemilik';
    protected $fillable = ['user_id', 'nama_pemilik', 'no_telp'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
