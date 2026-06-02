<?php

namespace App\Services\Admin;

use App\Models\Mahasiswa;
use App\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use RuntimeException;

class ApprovalService
{
    private const DEFAULT_PASSWORD = 'password123';

    /**
     * Approve a buyer application and promote it into the main MySQL users table.
     */
    public function approve(int $applicationId): User
    {
        return DB::transaction(function () use ($applicationId) {
            $application = DB::table('buyer_applications')
                ->where('id', $applicationId)
                ->lockForUpdate()
                ->first();

            if (! $application) {
                throw new ModelNotFoundException('Pendaftaran mahasiswa tidak ditemukan.');
            }

            if (($application->status ?? 'pending') !== 'pending') {
                throw new RuntimeException('Pendaftaran ini sudah diproses sebelumnya.');
            }

            $email = $application->email ?? null;
            $nim = $application->nim ?? null;

            if (! $email || ! $nim) {
                throw new RuntimeException('Data pendaftaran belum lengkap. Email dan NIM wajib tersedia.');
            }

            if (User::where('email', $email)->exists()) {
                throw new RuntimeException('Email pendaftar sudah terdaftar sebagai user.');
            }

            if (Mahasiswa::where('nim', $nim)->exists()) {
                throw new RuntimeException('NIM pendaftar sudah terdaftar sebagai mahasiswa.');
            }

            $name = $application->nama_mahasiswa
                ?? $application->name
                ?? $application->username
                ?? Str::before($email, '@');

            $user = User::create([
                'username' => $name,
                'email' => $email,
                'password' => Hash::make(self::DEFAULT_PASSWORD),
                'role' => 'mahasiswa',
                'status_akun' => 'aktif',
            ]);

            Mahasiswa::create([
                'user_id' => $user->id,
                'nama_mahasiswa' => $name,
                'nim' => $nim,
                'no_telp' => $application->no_telp ?? $application->phone ?? null,
                'masa_aktif' => $application->masa_aktif ?? null,
            ]);

            DB::table('buyer_applications')
                ->where('id', $applicationId)
                ->update([
                    'status' => 'approved',
                    'updated_at' => now(),
                ]);

            return $user;
        });
    }

    /**
     * Rejecting keeps the application row for admin audit/history.
     */
    public function reject(int $applicationId, ?string $reason = null): void
    {
        $updates = [
            'status' => 'rejected',
            'updated_at' => now(),
        ];

        if ($reason && Schema::hasColumn('buyer_applications', 'rejection_reason')) {
            $updates['rejection_reason'] = $reason;
        }

        $affected = DB::table('buyer_applications')
            ->where('id', $applicationId)
            ->where('status', 'pending')
            ->update($updates);

        if ($affected === 0) {
            throw new ModelNotFoundException('Pendaftaran tidak ditemukan atau sudah diproses sebelumnya.');
        }
    }

    public function defaultPassword(): string
    {
        return self::DEFAULT_PASSWORD;
    }
}
