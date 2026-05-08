<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pegawai extends Model // Berubah dari KantinPegawai
{
    use HasFactory;

    protected $table = 'pegawai'; // Mengikuti nama tabel baru
    protected $fillable = ['kantin_id', 'nama_karyawan', 'no_telp'];
    
    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class);
    }
}