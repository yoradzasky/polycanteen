<?php

namespace Database\Seeders;

use App\Models\BuyerApplication;
use App\Models\Mahasiswa;
use App\Models\User;
use App\Services\Admin\ApprovalService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class BuyerApplicationSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->orderBy('id')->first();

        $applications = [
            ['name' => 'Aditya Nugraha', 'nim' => '22410101001', 'phone' => '081300000001', 'email' => 'aditya.nugraha@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 1],
            ['name' => 'Nabila Putri', 'nim' => '22410101002', 'phone' => '081300000002', 'email' => 'nabila.putri@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 2],
            ['name' => 'Fajar Maulana', 'nim' => '22410101003', 'phone' => '081300000003', 'email' => 'fajar.maulana@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 3],
            ['name' => 'Aulia Rahman', 'nim' => '22410101004', 'phone' => '081300000004', 'email' => 'aulia.rahman@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 4],
            ['name' => 'Kevin Saputra', 'nim' => '22410101005', 'phone' => '081300000005', 'email' => 'kevin.saputra@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 5],
            ['name' => 'Maya Kartika', 'nim' => '22410101006', 'phone' => '081300000006', 'email' => 'maya.kartika@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 6],
            ['name' => 'Dimas Prakoso', 'nim' => '22410101007', 'phone' => '081300000007', 'email' => 'dimas.prakoso@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 7],
            ['name' => 'Rara Anggraini', 'nim' => '22410101008', 'phone' => '081300000008', 'email' => 'rara.anggraini@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 8],
            ['name' => 'Bagus Wicaksono', 'nim' => '22410101009', 'phone' => '081300000009', 'email' => 'bagus.wicaksono@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 9],
            ['name' => 'Intan Permata', 'nim' => '22410101010', 'phone' => '081300000010', 'email' => 'intan.permata@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 10],
            ['name' => 'Rizal Hakim', 'nim' => '22410101011', 'phone' => '081300000011', 'email' => 'rizal.hakim@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 11],
            ['name' => 'Tiara Melati', 'nim' => '22410101012', 'phone' => '081300000012', 'email' => 'tiara.melati@student.politeknik.ac.id', 'status' => 'pending', 'days_ago' => 12],
            ['name' => 'Yoga Prasetyo', 'nim' => '22410101013', 'phone' => '081300000013', 'email' => 'yoga.prasetyo@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 13],
            ['name' => 'Citra Lestari', 'nim' => '22410101014', 'phone' => '081300000014', 'email' => 'citra.lestari@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 14],
            ['name' => 'Hafiz Ramadhan', 'nim' => '22410101015', 'phone' => '081300000015', 'email' => 'hafiz.ramadhan@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 15],
            ['name' => 'Putri Amelia', 'nim' => '22410101016', 'phone' => '081300000016', 'email' => 'putri.amelia@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 16],
            ['name' => 'Rendi Kurniawan', 'nim' => '22410101017', 'phone' => '081300000017', 'email' => 'rendi.kurniawan@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 17],
            ['name' => 'Salsa Maharani', 'nim' => '22410101018', 'phone' => '081300000018', 'email' => 'salsa.maharani@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 18],
            ['name' => 'Farhan Abdillah', 'nim' => '22410101019', 'phone' => '081300000019', 'email' => 'farhan.abdillah@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 19],
            ['name' => 'Laras Oktaviani', 'nim' => '22410101020', 'phone' => '081300000020', 'email' => 'laras.oktaviani@student.politeknik.ac.id', 'status' => 'approved', 'days_ago' => 20],
        ];

        foreach ($applications as $data) {
            $createdAt = now()->subDays($data['days_ago']);
            $approvedAt = $data['status'] === 'approved' ? $createdAt->copy()->addHours(4) : null;
            $user = $data['status'] === 'approved' ? $this->upsertApprovedStudent($data) : null;

            $application = BuyerApplication::updateOrCreate(
                ['email' => $data['email']],
                [
                    'user_id' => $user?->id,
                    'reviewed_by' => $data['status'] === 'approved' ? $admin?->id : null,
                    'name' => $data['name'],
                    'nim' => $data['nim'],
                    'phone' => $data['phone'],
                    'account_expires_at' => '2027-08-31',
                    'foto_ktm_path' => null,
                    'status' => $data['status'],
                    'rejection_reason' => null,
                    'approved_at' => $approvedAt,
                    'rejected_at' => null,
                ]
            );

            $application->forceFill([
                'created_at' => $createdAt,
                'updated_at' => $approvedAt ?? $createdAt,
            ])->save();
        }
    }

    private function upsertApprovedStudent(array $data): User
    {
        $user = User::updateOrCreate(
            ['email' => $data['email']],
            [
                'nama_lengkap' => $data['name'],
                'password' => Hash::make(ApprovalService::DEFAULT_PASSWORD),
                'status_akun' => 'aktif',
                'role' => 'mahasiswa',
                'foto_profile' => null,
            ]
        );

        Mahasiswa::updateOrCreate(
            ['nim' => $data['nim']],
            [
                'user_id' => $user->id,
                'nama_mahasiswa' => $data['name'],
                'no_telp' => $data['phone'],
                'masa_aktif' => '2027-08-31',
                'foto_profil_path' => null,
            ]
        );

        return $user;
    }
}
