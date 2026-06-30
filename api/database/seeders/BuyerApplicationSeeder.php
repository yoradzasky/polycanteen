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

        // Jurusan-jurusan yang ada di Politeknik Negeri Semarang
        $jurusanPolines = [
            'Teknik Sipil',
            'Teknik Mesin',
            'Teknik Elektro',
            'Akuntansi',
            'Administrasi Bisnis',
        ];

        $applications = [
            ['name' => 'Aditya Nugraha',    'nim' => '4.33.23.1.01', 'jurusan' => 'Teknik Elektro',       'phone' => '081300000001', 'email' => 'aditya.nugraha@mhs.polines.ac.id',    'status' => 'pending', 'days_ago' => 1],
            ['name' => 'Nabila Putri',       'nim' => '4.41.23.1.02', 'jurusan' => 'Akuntansi',            'phone' => '081300000002', 'email' => 'nabila.putri@mhs.polines.ac.id',      'status' => 'pending', 'days_ago' => 2],
            ['name' => 'Fajar Maulana',      'nim' => '4.21.23.1.03', 'jurusan' => 'Teknik Mesin',         'phone' => '081300000003', 'email' => 'fajar.maulana@mhs.polines.ac.id',     'status' => 'pending', 'days_ago' => 3],
            ['name' => 'Aulia Rahman',       'nim' => '4.52.23.1.04', 'jurusan' => 'Administrasi Bisnis',  'phone' => '081300000004', 'email' => 'aulia.rahman@mhs.polines.ac.id',      'status' => 'pending', 'days_ago' => 4],
            ['name' => 'Kevin Saputra',      'nim' => '4.11.23.1.05', 'jurusan' => 'Teknik Sipil',         'phone' => '081300000005', 'email' => 'kevin.saputra@mhs.polines.ac.id',     'status' => 'pending', 'days_ago' => 5],
            ['name' => 'Maya Kartika',       'nim' => '4.33.23.1.06', 'jurusan' => 'Teknik Elektro',       'phone' => '081300000006', 'email' => 'maya.kartika@mhs.polines.ac.id',      'status' => 'pending', 'days_ago' => 6],
            ['name' => 'Dimas Prakoso',      'nim' => '4.21.23.1.07', 'jurusan' => 'Teknik Mesin',         'phone' => '081300000007', 'email' => 'dimas.prakoso@mhs.polines.ac.id',     'status' => 'pending', 'days_ago' => 7],
            ['name' => 'Rara Anggraini',     'nim' => '4.41.23.1.08', 'jurusan' => 'Akuntansi',            'phone' => '081300000008', 'email' => 'rara.anggraini@mhs.polines.ac.id',    'status' => 'pending', 'days_ago' => 8],
            ['name' => 'Bagus Wicaksono',    'nim' => '4.11.23.1.09', 'jurusan' => 'Teknik Sipil',         'phone' => '081300000009', 'email' => 'bagus.wicaksono@mhs.polines.ac.id',   'status' => 'pending', 'days_ago' => 9],
            ['name' => 'Intan Permata',      'nim' => '4.52.23.1.10', 'jurusan' => 'Administrasi Bisnis',  'phone' => '081300000010', 'email' => 'intan.permata@mhs.polines.ac.id',     'status' => 'pending', 'days_ago' => 10],
            ['name' => 'Rizal Hakim',        'nim' => '4.33.23.1.11', 'jurusan' => 'Teknik Elektro',       'phone' => '081300000011', 'email' => 'rizal.hakim@mhs.polines.ac.id',       'status' => 'pending', 'days_ago' => 11],
            ['name' => 'Tiara Melati',       'nim' => '4.41.23.1.12', 'jurusan' => 'Akuntansi',            'phone' => '081300000012', 'email' => 'tiara.melati@mhs.polines.ac.id',      'status' => 'pending', 'days_ago' => 12],
            ['name' => 'Yoga Prasetyo',      'nim' => '4.21.23.1.13', 'jurusan' => 'Teknik Mesin',         'phone' => '081300000013', 'email' => 'yoga.prasetyo@mhs.polines.ac.id',     'status' => 'approved', 'days_ago' => 13],
            ['name' => 'Citra Lestari',      'nim' => '4.52.23.1.14', 'jurusan' => 'Administrasi Bisnis',  'phone' => '081300000014', 'email' => 'citra.lestari@mhs.polines.ac.id',     'status' => 'approved', 'days_ago' => 14],
            ['name' => 'Hafiz Ramadhan',     'nim' => '4.11.23.1.15', 'jurusan' => 'Teknik Sipil',         'phone' => '081300000015', 'email' => 'hafiz.ramadhan@mhs.polines.ac.id',    'status' => 'approved', 'days_ago' => 15],
            ['name' => 'Putri Amelia',       'nim' => '4.33.23.1.16', 'jurusan' => 'Teknik Elektro',       'phone' => '081300000016', 'email' => 'putri.amelia@mhs.polines.ac.id',      'status' => 'approved', 'days_ago' => 16],
            ['name' => 'Rendi Kurniawan',    'nim' => '4.41.23.1.17', 'jurusan' => 'Akuntansi',            'phone' => '081300000017', 'email' => 'rendi.kurniawan@mhs.polines.ac.id',   'status' => 'approved', 'days_ago' => 17],
            ['name' => 'Salsa Maharani',     'nim' => '4.21.23.1.18', 'jurusan' => 'Teknik Mesin',         'phone' => '081300000018', 'email' => 'salsa.maharani@mhs.polines.ac.id',    'status' => 'approved', 'days_ago' => 18],
            ['name' => 'Farhan Abdillah',    'nim' => '4.52.23.1.19', 'jurusan' => 'Administrasi Bisnis',  'phone' => '081300000019', 'email' => 'farhan.abdillah@mhs.polines.ac.id',   'status' => 'approved', 'days_ago' => 19],
            ['name' => 'Laras Oktaviani',    'nim' => '4.11.23.1.20', 'jurusan' => 'Teknik Sipil',         'phone' => '081300000020', 'email' => 'laras.oktaviani@mhs.polines.ac.id',   'status' => 'approved', 'days_ago' => 20],
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
                    'jurusan' => $data['jurusan'],
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
                'jurusan' => $data['jurusan'],
                'no_telp' => $data['phone'],
                'masa_aktif' => '2027-08-31',
                'foto_profil_path' => null,
            ]
        );

        return $user;
    }
}
