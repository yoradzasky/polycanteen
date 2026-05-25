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
        'total_harga',
        'nomor_antrian',
        'catatan_pesanan',
        'alasan_penolakan',
    ];

    /**
     * Auto-generate nomor_antrian saat status_pesanan berubah ke 'dibayar'.
     */
    protected static function boot()
    {
        parent::boot();

        static::updating(function (Pesanan $pesanan) {
            if (
                $pesanan->isDirty('status_pesanan')
                && $pesanan->status_pesanan === 'dibayar'
                && empty($pesanan->nomor_antrian)
            ) {
                $pesanan->nomor_antrian = static::generateNomorAntrian($pesanan->kantin_id);
            }
        });
    }

    /**
     * Generate nomor antrian format "A-001" per kantin per hari.
     * Menggunakan logika latest()->first() untuk mencegah bug duplikat antrian.
     */
    public static function generateNomorAntrian(int $kantinId): string
    {
        $today = now()->toDateString();

        // Ambil pesanan terakhir yang sudah punya nomor antrian pada hari itu untuk kantin ini
        $lastPesanan = static::where('kantin_id', $kantinId)
            ->whereDate('created_at', $today)
            ->whereNotNull('nomor_antrian')
            ->latest('id') // Mengurutkan dari ID terbaru/terbesar
            ->first();

        $lastNumber = 0;

        if ($lastPesanan) {
            // Ekstrak angka dari format "A-001"
            // substr($string, 2) memotong 2 karakter pertama ("A-") sehingga tersisa angkanya saja
            $lastNumber = (int) substr($lastPesanan->nomor_antrian, 2);
        }

        // Tambah 1 pada angka terakhir, lalu format ulang dengan padding 0 di kiri
        return 'A-' . str_pad($lastNumber + 1, 3, '0', STR_PAD_LEFT);
    }

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

    public function ulasan(): HasOne
    {
        return $this->hasOne(Ulasan::class);
    }
}