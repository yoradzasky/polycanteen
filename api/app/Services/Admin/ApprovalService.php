<?php

namespace App\Services\Admin;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Firestore;

class ApprovalService
{
    protected $firestore;

    public function __construct(Firestore $firestore)
    {
        $this->firestore = $firestore;
    }

    /**
     * Setujui pendaftaran mahasiswa.
     * Logika ini dibungkus dalam database transaction untuk memastikan
     * perpindahan data dari buyer_applications ke users aman.
     *
     * @param object $application Data pendaftaran (dari tabel buyer_applications)
     * @return User
     * @throws \Exception
     */
    public function approve($application)
    {
        return DB::transaction(function () use ($application) {
            // 1. Pindahkan dan buat data di tabel users
            $user = User::create([
                'name' => $application->name,
                'email' => $application->email,
                // Mengatur password default untuk akun yang disetujui
                'password' => Hash::make('password123'),
                'role' => 'mahasiswa', // Atur role sebagai mahasiswa
                // Field lain sesuai dengan struktur tabel user, misalnya nim
                // 'nim' => $application->nim, 
            ]);

            // 2. Perbarui status di tabel pendaftaran menjadi disetujui
            DB::table('buyer_applications')
                ->where('id', $application->id)
                ->update(['status' => 'approved']);

            // 3. Sinkronisasikan data user baru ke dalam Firebase Firestore
            $this->syncToFirestore($user);

            return $user;
        });
    }

    /**
     * Tolak pendaftaran mahasiswa.
     *
     * @param object $application
     * @param string $reason Alasan penolakan dari admin
     * @return void
     */
    public function reject($application, string $reason = '')
    {
        // Update status pendaftaran menjadi rejected dan simpan alasan penolakan
        DB::table('buyer_applications')
            ->where('id', $application->id)
            ->update([
                'status' => 'rejected',
                'rejection_reason' => $reason,
                'updated_at' => now(),
            ]);
    }

    /**
     * Sinkronisasi data user baru ke koleksi Firestore.
     * Menggunakan library kreait/laravel-firebase.
     *
     * @param User $user
     * @return void
     */
    protected function syncToFirestore(User $user)
    {
        try {
            $database = $this->firestore->database();
            
            // Referensi ke koleksi 'users' di Firestore
            $collection = $database->collection('users');

            // Gunakan ID dari database MySQL sebagai ID Dokumen Firestore agar konsisten
            $document = $collection->document((string) $user->id);
            
            // Set payload dokumen Firestore
            $document->set([
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'created_at' => $user->created_at->toIso8601String(),
                'status' => 'active',
            ]);
            
            Log::info("User {$user->id} successfully synced to Firestore.");
        } catch (\Exception $e) {
            // Log error jika terjadi kegagalan sinkronisasi, 
            // tanpa membatalkan transkasi MySQL (bergantung pada kebutuhan bisnis)
            Log::error("Failed to sync user {$user->id} to Firestore: " . $e->getMessage());
        }
    }
}
