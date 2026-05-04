<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class KantinPegawai extends Model
{
    protected $table = 'kantin_pegawai';
    protected $fillable = ['kantin_id', 'nama_karyawan', 'no_telp'];
    
    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class);
    }
}