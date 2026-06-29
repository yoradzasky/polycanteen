<?php

namespace App\Services;

use App\Models\Kantin;
use App\Models\Menu;
use App\Models\Pegawai;
use App\Models\Pemilik;
use App\Models\Pesanan;
use App\Models\PesananDetail;
use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class CanteenService
{
    /**
     * Mengambil daftar kantin dengan pagination untuk tabel utama dashboard admin.
     *
     * Eager load relasi pemilik beserta user-nya, hitung jumlah menu,
     * dan jumlahkan total penjualan dari pesanan yang sudah selesai.
     *
     * @param  array  $filters  Array filter opsional (nama_kantin, status_toko)
     * @param  int    $perPage  Jumlah item per halaman
     * @return \Illuminate\Pagination\LengthAwarePaginator
     */
    public function getPaginatedCanteens(array $filters, int $perPage = 8): LengthAwarePaginator
    {
        $query = Kantin::query()
            ->with('pemilik.user')
            ->withCount('menus')
            ->withSum(
                [
                    'pesanan as pesanan_sum_total_harga' => function ($q) {
                        $q->where('status_pesanan', 'selesai');
                    }
                ],
                'total_harga'
            );

        // Filter berdasarkan nama kantin (partial match)
        if (!empty($filters['nama_kantin'])) {
            $query->where('nama_kantin', 'like', '%' . $filters['nama_kantin'] . '%');
        }

        // Filter berdasarkan kode kantin (partial match)


        // Filter berdasarkan status toko (exact match)
        if (!empty($filters['status_toko'])) {
            $query->where('status_toko', $filters['status_toko']);
        }

        // Urutkan dari yang terbaru
        $query->latest();

        return $query->paginate($perPage);
    }

    /**
     * Mengambil profil kantin beserta statistik ringkasan untuk halaman detail.
     *
     * @param  int  $id  ID kantin
     * @return array Berisi key: kantin (Model), total_penjualan (int|float), total_menu_terjual (int)
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     */
    public function getCanteenProfileAndStats(int $id): array
    {
        // Ambil data kantin dengan relasi pemilik dan user serta pegawai
        $kantin = Kantin::with(['pemilik.user', 'pegawai.user'])->findOrFail($id);

        // Hitung total penjualan (Rp) dari pesanan selesai
        $totalPenjualan = $kantin->pesanan()
            ->where('status_pesanan', 'selesai')
            ->sum('total_harga');

        // Hitung total menu terjual (qty) dari detail pesanan yang selesai
        $totalMenuTerjual = PesananDetail::whereHas('pesanan', function ($q) use ($id) {
            $q->where('kantin_id', $id)
                ->where('status_pesanan', 'selesai');
        })->sum('jumlah_pesanan');

        return [
            'kantin' => $kantin,
            'total_penjualan' => $totalPenjualan,
            'total_menu_terjual' => (int) $totalMenuTerjual,
        ];
    }

    /**
     * Mengambil daftar menu milik kantin tertentu dengan pagination.
     *
     * Menjumlahkan jumlah pesanan per menu, hanya dari pesanan yang sudah selesai.
     *
     * @param  int  $id       ID kantin
     * @param  int  $perPage  Jumlah item per halaman
     * @return \Illuminate\Pagination\LengthAwarePaginator
     */
    public function getPaginatedMenus(int $id, int $perPage = 5): LengthAwarePaginator
    {
        return Menu::where('kantin_id', $id)
            ->withSum(
                [
                    'pesananDetails as pesanan_details_sum_jumlah_pesanan' => function ($q) {
                        // Hanya hitung dari pesanan induk yang berstatus selesai
                        $q->whereHas('pesanan', function ($query) {
                            $query->where('status_pesanan', 'selesai');
                        });
                    }
                ],
                'jumlah_pesanan'
            )
            ->paginate($perPage);
    }

    /**
     * Mengambil data aktivitas penjualan harian kantin dalam N hari terakhir untuk chart.
     *
     * @param  int  $id    ID kantin
     * @param  int  $days  Jumlah hari ke belakang
     * @return \Illuminate\Support\Collection
     */
    public function getDailySalesActivity(int $id, int $days = 30): Collection
    {
        return Pesanan::where('kantin_id', $id)
            ->where('status_pesanan', 'selesai')
            ->where('created_at', '>=', now()->subDays($days))
            ->selectRaw('DATE(created_at) as tanggal, COUNT(id) as jumlah_pesanan, SUM(total_harga) as total_pendapatan')
            ->groupBy('tanggal')
            ->orderByDesc('tanggal')
            ->get();
    }

    /**
     * Membuat entitas kantin baru beserta akun pemilik (dan opsional karyawan).
     *
     * Seluruh operasi dibungkus dalam DB::transaction untuk menjaga konsistensi data.
     *
     * @param  array  $data  Data kantin, pemilik, dan opsional karyawan
     * @return \App\Models\Kantin
     *
     * @throws \Exception
     */
    public function createCanteen(array $data): Kantin
    {
        try {
            return DB::transaction(function () use ($data) {
                // Tahap 1: Buat record kantin
                $kantin = Kantin::create([

                    'nama_kantin' => $data['nama_kantin'],
                    'lokasi_lengkap' => $data['lokasi_lengkap'],
                    'latitude' => $data['latitude'] ?? null,
                    'longitude' => $data['longitude'] ?? null,
                    'status_toko' => 'tutup',
                ]);

                // Tahap 2: Buat akun user untuk pemilik
                $userPemilik = User::create([
                    'nama_lengkap' => strstr($data['email'], '@', true) . rand(1000, 9999),
                    'email' => $data['email'],
                    'password' => Hash::make('password'),
                    'role' => 'pemilik',
                    'status_akun' => 'aktif',
                ]);

                // Tahap 3: Buat profil pemilik yang terhubung ke kantin dan user
                Pemilik::create([
                    'kantin_id' => $kantin->id,
                    'user_id' => $userPemilik->id,
                    'nama_pemilik' => $data['nama_pemilik'],
                    'no_telp' => $data['no_telp'],
                ]);

                // Tahap 4: Buat karyawan (opsional) jika data karyawan tersedia
                if (!empty($data['karyawan']) && is_array($data['karyawan'])) {
                    foreach ($data['karyawan'] as $karyawan) {
                        // Buat akun user untuk setiap karyawan
                        $userKaryawan = User::create([
                            'nama_lengkap' => strstr($karyawan['email'], '@', true) . rand(1000, 9999),
                            'email' => $karyawan['email'],
                            'password' => Hash::make('password'),
                            'role' => 'pegawai',
                            'status_akun' => 'aktif',
                        ]);

                        // Buat record pegawai yang terhubung ke user dan kantin
                        Pegawai::create([
                            'user_id' => $userKaryawan->id,
                            'kantin_id' => $kantin->id,
                            'nama_karyawan' => $karyawan['nama_karyawan'] ?? null,
                            'no_telp' => $karyawan['no_telp'] ?? null,
                        ]);
                    }
                }

                return $kantin;
            });
        } catch (\Exception $e) {
            throw $e;
        }
    }

    /**
     * Memperbarui data kantin dan akun terkait.
     *
     * Seluruh operasi dibungkus dalam DB::transaction untuk menjaga konsistensi data.
     *
     * @param  int    $id    ID kantin
     * @param  array  $data  Data yang akan diperbarui
     * @return \App\Models\Kantin
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     * @throws \Illuminate\Validation\ValidationException
     * @throws \Exception
     */
    public function updateCanteen(int $id, array $data): Kantin
    {
        try {
            return DB::transaction(function () use ($id, $data) {
                // Tahap 1: Update data kantin
                $kantin = Kantin::findOrFail($id);
                $kantin->update([
                    'nama_kantin' => $data['nama_kantin'],
                    'lokasi_lengkap' => $data['lokasi_lengkap'],
                    'latitude' => $data['latitude'] ?? $kantin->latitude,
                    'longitude' => $data['longitude'] ?? $kantin->longitude,
                ]);

                // Tahap 2: Update profil pemilik
                $kantin->pemilik()->update([
                    'nama_pemilik' => $data['nama_pemilik'],
                    'no_telp' => $data['no_telp'],
                ]);

                // Tahap 3: Update email pemilik jika berubah
                $userPemilik = $kantin->pemilik->user;
                if (isset($data['email']) && $data['email'] !== $userPemilik->email) {
                    // Validasi email unik di luar user saat ini
                    $emailExists = User::where('email', $data['email'])
                        ->where('id', '!=', $userPemilik->id)
                        ->exists();

                    if ($emailExists) {
                        throw new \Illuminate\Validation\ValidationException(
                            validator([], []),
                            response()->json(['message' => 'Email sudah digunakan oleh akun lain.'], 422)
                        );
                    }

                    $userPemilik->update(['email' => $data['email']]);
                }

                // Tahap 4: Sinkronisasi data karyawan
                $payloadPegawaiIds = collect($data['karyawan'] ?? [])->pluck('id')->filter()->toArray();

                // Suspend akun & hapus record pegawai yang tidak ada di form (dihapus oleh admin)
                $pegawaiDihapus = $kantin->pegawai()->whereNotIn('id', $payloadPegawaiIds)->get();
                foreach ($pegawaiDihapus as $pegawai) {
                    if ($pegawai->user) {
                        $pegawai->user->update(['status_akun' => 'suspend']);
                    }
                    $pegawai->delete();
                }

                if (isset($data['karyawan']) && is_array($data['karyawan'])) {
                    foreach ($data['karyawan'] as $karyawanData) {
                        if (!empty($karyawanData['id'])) {
                            // Update karyawan existing
                            $pegawai = Pegawai::findOrFail($karyawanData['id']);
                            $pegawai->update([
                                'nama_karyawan' => $karyawanData['nama_karyawan'] ?? $pegawai->nama_karyawan,
                                'no_telp' => $karyawanData['no_telp'] ?? $pegawai->no_telp,
                            ]);

                            // Update email user karyawan jika tersedia
                            if (isset($karyawanData['email'])) {
                                $pegawai->user->update([
                                    'email' => $karyawanData['email'],
                                ]);
                            }
                        } else {
                            // Buat user dan pegawai baru
                            $userBaru = User::create([
                                'nama_lengkap' => strstr($karyawanData['email'], '@', true) . rand(1000, 9999),
                                'email' => $karyawanData['email'],
                                'password' => Hash::make('password'),
                                'role' => 'pegawai',
                                'status_akun' => 'aktif',
                            ]);

                            Pegawai::create([
                                'user_id' => $userBaru->id,
                                'kantin_id' => $kantin->id,
                                'nama_karyawan' => $karyawanData['nama_karyawan'] ?? null,
                                'no_telp' => $karyawanData['no_telp'] ?? null,
                            ]);
                        }
                    }
                }

                return $kantin->fresh();
            });
        } catch (\Exception $e) {
            throw $e;
        }
    }

    /**
     * Menonaktifkan kantin dan semua akun terkait (soft delete).
     *
     * Suspend akun pemilik dan semua pegawai, kemudian soft delete kantin.
     *
     * @param  int  $id  ID kantin
     * @return bool
     *
     * @throws \Illuminate\Database\Eloquent\ModelNotFoundException
     * @throws \Exception
     */
    public function deleteCanteen(int $id): bool
    {
        try {
            return DB::transaction(function () use ($id) {
                $kantin = Kantin::findOrFail($id);

                // Tahap 1: Suspend akun pemilik
                $kantin->pemilik->user()->update(['status_akun' => 'suspend']);

                // Tahap 2: Suspend semua akun pegawai kantin ini
                $userIds = $kantin->pegawai()->pluck('user_id');
                if ($userIds->isNotEmpty()) {
                    User::whereIn('id', $userIds)->update(['status_akun' => 'suspend']);
                }

                // Tahap 3: Soft delete kantin (mengisi kolom deleted_at)
                $kantin->delete();

                return true;
            });
        } catch (\Exception $e) {
            throw $e;
        }
    }
}