<?php

namespace App\Services\Admin;

use App\Models\BuyerApplication;
use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use RuntimeException;

class ApprovalService
{
    /**
     * Password awal yang dibuat saat akun mahasiswa disetujui.
     * Pada flow produksi, nilai ini sebaiknya dikirim lewat email atau dipaksa ganti saat login pertama.
     */
    public const DEFAULT_PASSWORD = 'Mahasiswa123!';

    /**
     * Menyetujui pengajuan mahasiswa secara atomik.
     *
     * Satu transaksi memastikan status pengajuan, data user, dan profil mahasiswa selalu konsisten.
     */
    public function approve(int $applicationId, ?int $reviewedBy = null): array
    {
        return DB::transaction(function () use ($applicationId, $reviewedBy) {
            // Kunci baris pengajuan agar dua admin tidak bisa memproses data yang sama bersamaan.
            $application = BuyerApplication::query()
                ->whereKey($applicationId)
                ->lockForUpdate()
                ->first();

            if (! $application) {
                throw (new ModelNotFoundException())->setModel(BuyerApplication::class, [$applicationId]);
            }

            if ($application->status !== 'pending') {
                throw new RuntimeException('Pengajuan ini sudah pernah diproses.');
            }

            $emailExists = User::where('email', $application->email)->exists();
            $nimExists = Mahasiswa::where('nim', $application->nim)->exists();

            if ($emailExists || $nimExists) {
                throw new RuntimeException('Email atau NIM sudah terdaftar sebagai akun mahasiswa.');
            }

            $defaultPassword = self::DEFAULT_PASSWORD;

            // Buat akun login utama di tabel users MySQL.
            $user = User::create([
                'nama_lengkap' => $application->name,
                'email' => $application->email,
                'password' => $application->password ?? Hash::make($defaultPassword),
                'role' => 'mahasiswa',
                'status_akun' => 'aktif',
                'foto_profile' => null,
                'fcm_token' => $application->fcm_token,
            ]);

            // Simpan detail domain mahasiswa pada tabel profil mahasiswa.
            Mahasiswa::create([
                'user_id' => $user->id,
                'nama_mahasiswa' => $application->name,
                'nim' => $application->nim,
                'jurusan' => $application->jurusan,
                'no_telp' => $application->phone,
                'masa_aktif' => $application->account_expires_at,
                'foto_profil_path' => null,
            ]);

            // Tandai pengajuan sebagai selesai agar riwayat approval tetap tercatat.
            $application->forceFill([
                'status' => 'approved',
                'user_id' => $user->id,
                'reviewed_by' => $reviewedBy,
                'approved_at' => now(),
            ])->save();

            // Kirim notifikasi FCM
            try {
                $fcmService = app(\App\Services\FcmNotificationService::class);
                $fcmService->sendToBuyerApplication($application, 'Pendaftaran Disetujui', 'Selamat, akun pendaftaran PolyCanteen Anda telah disetujui!');
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('FCM Approval Error: ' . $e->getMessage());
            }

            return [
                'user' => $user,
                'is_default' => empty($application->password),
                'default_password' => $defaultPassword,
            ];
        });
    }

    /**
     * Menolak pengajuan mahasiswa dan menyimpan alasan penolakan.
     */
    public function reject(int $applicationId, string $reason, ?int $reviewedBy = null): void
    {
        DB::transaction(function () use ($applicationId, $reason, $reviewedBy) {
            $application = BuyerApplication::query()
                ->whereKey($applicationId)
                ->lockForUpdate()
                ->first();

            if (! $application) {
                throw (new ModelNotFoundException())->setModel(BuyerApplication::class, [$applicationId]);
            }

            if ($application->status !== 'pending') {
                throw new RuntimeException('Pengajuan ini sudah pernah diproses.');
            }

            $application->forceFill([
                'status' => 'rejected',
                'rejection_reason' => Str::limit($reason, 500, ''),
                'reviewed_by' => $reviewedBy,
                'rejected_at' => now(),
            ])->save();

            // Kirim notifikasi FCM
            try {
                $fcmService = app(\App\Services\FcmNotificationService::class);
                $fcmService->sendToBuyerApplication($application, 'Pendaftaran Ditolak', 'Maaf, pendaftaran akun PolyCanteen Anda ditolak: ' . $reason);
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('FCM Rejection Error: ' . $e->getMessage());
            }
        });
    }
}
