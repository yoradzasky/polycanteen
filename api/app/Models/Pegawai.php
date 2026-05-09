<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pegawai extends Model
{
    use HasFactory;

    protected $table = 'pegawai';

    // Pastikan user_id ada di sini agar tersimpan saat createCanteen()
    protected $fillable = ['user_id', 'kantin_id', 'nama_karyawan', 'no_telp'];

    // Relasi ke akun User untuk login
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Pegawai adalah anak dari Kantin
    public function kantin(): BelongsTo
    {
        return $this->belongsTo(Kantin::class, 'kantin_id', 'id');
    }
}