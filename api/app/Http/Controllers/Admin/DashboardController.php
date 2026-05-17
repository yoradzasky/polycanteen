<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\User;
use App\Models\Pesanan;
use Carbon\Carbon;
use Illuminate\Pagination\LengthAwarePaginator; // Wajib di-import!

class DashboardController extends Controller
{
    /**
     * Menampilkan halaman utama Dashboard Admin
     */
    public function index(Request $request)
    {
        $totalTransaksi = Pesanan::where('status_pesanan', 'selesai')->sum('total_harga');
        $totalPembeli = User::where('role', 'mahasiswa')->count();
        $totalKantin = \Illuminate\Support\Facades\DB::table('kantin')->count();

        // Oper parameter request ke fungsi agar bisa membaca nomor halaman (?page=2)
        $aktivitas = $this->getRecentActivities($request);

        return Inertia::render('Dashboard/Index', [ 
            'totalTransaksi' => (int) $totalTransaksi,
            'totalPembeli'   => $totalPembeli,
            'totalKantin'    => $totalKantin,
            'aktivitas'      => $aktivitas,
        ]);
    }

    /**
     * Mengambil aktivitas terbaru dengan PAGINATION beneran
     */
    private function getRecentActivities(Request $request)
    {
        // 1. Ambil transaksi (Batasi misal 100 data terbaru agar browser tidak berat)
        $transaksi = Pesanan::with(['mahasiswa.user', 'kantin'])
            ->orderBy('created_at', 'desc')
            ->limit(100) 
            ->get()
            ->map(function ($pesanan) {
                $fotoProfile = $pesanan->mahasiswa?->user?->foto_profile ?? 'https://ui-avatars.com/api/?name=U&background=gray&color=fff';
                
                return [
                    'id' => $pesanan->id,
                    // Pastikan memanggil kolom nama_mahasiswa atau username yang benar
                    'nama' => $pesanan->mahasiswa?->nama_mahasiswa ?? $pesanan->mahasiswa?->user?->username ?? 'Unknown',
                    'userId' => $pesanan->mahasiswa?->user_id ?? $pesanan->mahasiswa_id,
                    'fotoProfile' => $fotoProfile,
                    'tipe' => 'Transaksi Pembelian',
                    'kantin' => $pesanan->kantin?->nama_kantin ?? '-',
                    'jumlah' => 'Rp ' . number_format($pesanan->total_harga, 0, ',', '.'),
                    'tanggal' => $pesanan->created_at->format('d M Y, H:i'),
                    'status' => ucfirst($pesanan->status_pesanan),
                    'tipeAktivitas' => 'transaksi',
                    'timestamp_asli' => $pesanan->created_at 
                ];
            });

        // 2. Ambil registrasi akun baru (Batasi misal 50 terbaru)
        $registrasi = User::where('role', 'mahasiswa')
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get()
            ->map(function ($user) {
                $fotoProfile = $user->foto_profile ?? 'https://ui-avatars.com/api/?name=' . urlencode($user->username) . '&background=random&color=fff';
                
                return [
                    'id' => $user->id,
                    // GUNAKAN $user->username
                    'nama' => $user->username ?? 'Unknown', 
                    'userId' => $user->id,
                    'fotoProfile' => $fotoProfile,
                    'tipe' => 'Registrasi Akun Baru',
                    'kantin' => '-',
                    'jumlah' => '-',
                    'tanggal' => $user->created_at->format('d M Y, H:i'),
                    'status' => 'Selesai',
                    'tipeAktivitas' => 'registrasi',
                    'timestamp_asli' => $user->created_at 
                ];
            });

        // 3. Gabungkan dan Urutkan
        $semuaAktivitas = collect($transaksi)->merge($registrasi)
            ->sortByDesc('timestamp_asli')
            ->values() // Mengembalikan kunci array menjadi urut (0, 1, 2...)
            ->toArray(); // UBAH MENJADI ARRAY

        return $semuaAktivitas; // Kirim array ini langsung ke React
    }
}