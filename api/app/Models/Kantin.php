<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kantin extends Model
{
    protected $table = 'kantin';
    protected $fillable = ['user_id', 'nama_kantin', 'longitude', 'latitude', 'status_toko', 'logo_path'];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function menus(): HasMany
    {
        return $this->hasMany(Menu::class);
    }
}