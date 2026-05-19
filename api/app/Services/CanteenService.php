<?php

namespace App\Services;

use App\Models\Kantin;
use App\Models\User;
use App\Models\Pemilik;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Kreait\Laravel\Firebase\Facades\Firebase;

class CanteenService
{
    private readonly mixed $firestore;

    public function __construct()
    {
        // MENGAPA: Sesuai aturan, inisialisasi Firestore di constructor.
        // Digunakan untuk sinkronisasi ke aplikasi mobile secara real-time. (Aturan 9)
        $this->firestore = Firebase::project()->firestore();
    }

    /**
     * Mengambil semua data kantin.
     */
    public function getAllCanteens(): array
    {
        try {
            // MENGAPA: Menggunakan model Eloquent secara langsung bukan DB::table()
            // agar semua observer, casting, dan event Laravel berjalan normal. (Aturan 8 & 20)
            $kantins = Kantin::orderBy('created_at', 'desc')->get();
            
            return [
                'success' => true,
                'message' => 'Berhasil memuat data kantin.',
                'data' => $kantins
            ];
        } catch (\Exception $e) {
            Log::error('Error getAllCanteens: ' . $e->getMessage());
            
            // MENGAPA: Mengikuti format return standar service layer yang diwajibkan (Aturan 7)
            return [
                'success' => false,
                'message' => 'Terjadi kesalahan saat memuat data kantin dari database.'
            ];
        }
    }

    /**
     * Membuat data kantin baru dan profil pemiliknya.
     */
    public function createCanteen(array $data): array
    {
        // MENGAPA: Setiap operasi yang menyentuh lebih dari satu tabel (Users, Kantin, Pemilik) 
        // WAJIB dibungkus dalam transaksi atomik untuk mencegah data yatim (orphan) jika gagal di tengah jalan. (Aturan 3)
        try {
            $result = DB::transaction(function () use ($data) {
                // 1. Buat User untuk pemilik
                $user = User::create([
                    'name' => $data['nama_pemilik'],
                    'email' => $data['email'],
                    // MENGAPA: Sesuai aturan sistem, menggunakan NIM mahasiswa (dari payload) 
                    // sebagai password default untuk kemudahan login pertama, yang diamankan dengan Hash::make(). (Aturan 5)
                    'password' => Hash::make($data['nim']),
                    'role' => 'pemilik',
                ]);

                // 2. Buat Kantin
                $kantin = Kantin::create([
                    'nama_kantin' => $data['nama_kantin'],
                    'lokasi_lengkap' => $data['lokasi_lengkap'] ?? null,
                    'status_toko' => 'tutup', // MENGAPA: Status awal selalu tutup sebelum dioperasikan
                ]);

                // 3. Buat Profil Pemilik
                Pemilik::create([
                    'user_id' => $user->id,
                    'kantin_id' => $kantin->id,
                    'nama_pemilik' => $data['nama_pemilik'],
                    'no_telp' => $data['no_telp'] ?? null,
                ]);

                return [
                    'kantin' => $kantin,
                    'user' => $user
                ];
            });
        } catch (\Exception $e) {
            Log::error('MySQL Transaction Error (Create Canteen): ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Gagal menyimpan pendaftaran kantin ke database utama.'
            ];
        }

        // MENGAPA: Sinkronisasi Firestore WAJIB di luar blok DB::transaction.
        // Firestore bukan bagian dari transaksi SQL; jika Firestore gagal, kita tidak 
        // ingin me-rollback pendaftaran sukses di MySQL (konsep Eventual Consistency). (Aturan 4)
        try {
            $kantin = $result['kantin'];
            $user = $result['user'];
            
            $docRef = $this->firestore->collection('kantin')->document((string) $kantin->id);
            $docRef->set([
                'id' => $kantin->id,
                'nama_kantin' => $kantin->nama_kantin,
                'lokasi_lengkap' => $kantin->lokasi_lengkap,
                'status_toko' => $kantin->status_toko,
                'pemilik_id' => $user->id,
                'nama_pemilik' => $user->name,
                'created_at' => $kantin->created_at->toIso8601String(),
            ]);
        } catch (\Exception $e) {
            // MENGAPA: Hanya log error, tidak merubah return menjadi false agar operasi dianggap berhasil (Aturan 4)
            Log::error('Firestore Sync Error (Create Canteen): ' . $e->getMessage());
        }

        return [
            'success' => true,
            'message' => 'Kantin dan akun pemilik berhasil didaftarkan.',
            'data' => $result['kantin']
        ];
    }

    /**
     * Memproses persetujuan kantin (Guard Status example)
     * Method contoh untuk mengilustrasikan aturan Guard Status
     */
    public function approveApplication(Kantin $kantin): array
    {
        // MENGAPA: Guard status untuk mencegah pemrosesan ulang tanpa melempar Exception.
        // Jika sudah diproses, langsung kembalikan pesan error yang rapi. (Aturan 6)
        if ($kantin->status_toko !== 'pending') {
            return [
                'success' => false,
                'message' => 'Data tidak dapat diproses karena statusnya bukan pending.'
            ];
        }

        // Logika approval lanjutan...
        return [
            'success' => true,
            'message' => 'Kantin berhasil disetujui.',
            'data' => $kantin
        ];
    }
}
