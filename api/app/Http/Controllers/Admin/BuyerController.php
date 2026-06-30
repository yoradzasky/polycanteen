<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateExpirationRequest;
use App\Services\BuyerService;
use App\Models\User;
use App\Models\Mahasiswa;
use Carbon\Carbon;
use Inertia\Inertia;
use Illuminate\Http\Request;

class BuyerController extends Controller
{
    protected $buyerService;

    public function __construct(BuyerService $buyerService)
    {
        $this->buyerService = $buyerService;
    }

    /**
     * API untuk Live Search (Autocomplete)
     */
    public function apiSearch(Request $request)
    {
        $search = $request->input('search');
        
        if (empty($search)) {
            return response()->json([]);
        }

        // Cari mahasiswa berdasarkan nama atau nim
        $results = User::where('role', 'mahasiswa')
            ->where(function ($q) use ($search) {
                $q->where('nama_lengkap', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhereHas('mahasiswa', function ($subQ) use ($search) {
                      $subQ->where('nama_mahasiswa', 'like', "%{$search}%")
                           ->orWhere('nim', 'like', "%{$search}%");
                  });
            })
            ->with('mahasiswa')
            ->limit(5) // Batasi 5 hasil saja agar cepat
            ->get()
            ->map(function($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->mahasiswa->nama_mahasiswa ?? $user->nama_lengkap,
                    'nim' => $user->mahasiswa->nim ?? '-',
                ];
            });

        return response()->json($results);
    }

    public function index(Request $request)
    {
        $search = $request->input('search', '');

        $query = User::where('role', 'mahasiswa')
            ->where('status_akun', 'aktif')
            ->with(['mahasiswa' => function ($query) {
                $query->withCount('pesanan')
                      ->withSum('pesanan', 'total_harga'); 
            }]);

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('nama_lengkap', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhereHas('mahasiswa', function ($subQ) use ($search) {
                      $subQ->where('nama_mahasiswa', 'like', "%{$search}%")
                           ->orWhere('nim', 'like', "%{$search}%");
                  });
            });
        }


        /** @var \Illuminate\Pagination\LengthAwarePaginator $buyers */
        // Mengurutkan berdasarkan abjad (A-Z) dari kolom nama_mahasiswa di tabel mahasiswa
        $buyers = $query->orderBy(
            Mahasiswa::select('nama_mahasiswa')
                ->whereColumn('mahasiswa.user_id', 'users.id')
                ->limit(1),
            'asc' // 'asc' untuk A-Z, ubah ke 'desc' jika ingin Z-A
        )->paginate(10);
        $buyers->withQueryString(); 
        $buyers->through(function ($user) {
            $mhs = $user->mahasiswa;

            return [
                'id' => $user->id,
                'name' => $mhs->nama_mahasiswa ?? $user->nama_lengkap,
                'nim' => $mhs->nim ?? '-',
                'user_id' => '#USR-' . str_pad($user->id, 4, '0', STR_PAD_LEFT),
                'email' => $user->email,
                'phone' => $mhs->no_telp ?? '-',
                'total_rp' => 'Rp ' . number_format($mhs->pesanan_sum_total_harga ?? 0, 0, ',', '.'),
                'total_trx' => ($mhs->pesanan_count ?? 0) . ' transaksi',
                'status' => ucfirst($user->status_akun ?? 'aktif'),
                'date' => $user->created_at->translatedFormat('d M Y'),
                'time' => $user->created_at->format('H:i') . ' WIB',
                
                // --- PERBAIKAN: Ambil foto profil dari relasi mahasiswa ---
                'foto_profil_path' => $mhs->foto_profil_path ?? null,
                // -----------------------------------------------------------
                
                'active_until' => $mhs->masa_aktif ?? null 
            ];
        });

        return Inertia::render('Buyers/Index', [
            'buyers' => $buyers,
            'filters' => [
                'search' => $search
            ]
        ]);
    }

    public function show($id)
    {
        $user = User::with(['mahasiswa.pesanan.kantin'])->findOrFail($id);
        $mhs = $user->mahasiswa;

        $now = Carbon::now();
        $end = Carbon::parse($mhs?->masa_aktif ?? $now);
        
        // --- SOLUSI 1: Tanggal mulai paten ---
        $start = $user->created_at;
        
        $totalDays = max(1, $start->diffInDays($end));
        $passedDays = $start->diffInDays($now);
        $daysLeft = max(0, $now->diffInDays($end, false));
        
        $progressPercent = min(100, max(0, round(($passedDays / $totalDays) * 100)));
        $isActive = $daysLeft > 0;

        $pesanan = $mhs && $mhs->pesanan ? $mhs->pesanan : collect([]);

        $buyerData = [
            'id' => $user->id,
            'name' => $mhs?->nama_mahasiswa ?? $user->nama_lengkap,
            
            // --- TAMBAHAN BARU: Kirimkan NIM ---
            'nim' => $mhs?->nim ?? '-',
            // -----------------------------------
            
            'status' => ucfirst($user->status_akun ?? 'aktif'),
            'email' => $user->email,
            'phone' => $mhs?->no_telp ?? '-',
            'user_id' => '#PBY-' . str_pad($user->id, 5, '0', STR_PAD_LEFT),
            'join_date' => $user->created_at->translatedFormat('d M Y'),
            
            // --- PERBAIKAN: Ambil foto profil dan simpan ke key 'avatar' ---
            // Di dalam array $buyerData pada function show()
            'avatar' => $mhs?->foto_profil_path ?? null,
            // ----------------------------------------------------------------
            
            'subscription' => [
                'start_date' => $start->translatedFormat('j F Y'),
                'end_date' => $end->translatedFormat('j F Y'),
                'duration' => $totalDays . ' Hari',
                'days_left' => (int) $daysLeft,
                'progress_percent' => $progressPercent,
            ],
            
            'transactions' => $pesanan->sortByDesc('created_at')->map(function ($trx) {
                return [
                    'id' => $trx->id,
                    'date' => $trx->created_at->translatedFormat('d M Y'),
                    'kantin' => $trx->kantin->nama_kantin ?? 'Kantin Tidak Diketahui',
                    'total' => 'Rp ' . number_format($trx->total_harga, 0, ',', '.'),
                    'status' => ucfirst($trx->status_pesanan ?? $trx->status), 
                ];
            })->values()->all(),
            
            'total_transactions' => $pesanan->count(),
            'active_until' => $mhs?->masa_aktif ?? null
        ];

        return Inertia::render('Buyers/Show', [
            'buyer' => $buyerData
        ]);
    }

    public function updateExpiration(UpdateExpirationRequest $request, $id)
    {
        $validated = $request->validated();
        $this->buyerService->updateActiveUntil($id, $validated['active_until']);
        return redirect()->back()->with('success', 'Masa aktif mahasiswa berhasil diperbarui.');
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);
        $user->status_akun = 'nonaktif';
        $user->save();

        // Revoke all tokens so that if they are currently logged in, they get logged out
        $user->tokens()->delete();

        return redirect()->route('admin.buyers.index')->with('success', 'Akun mahasiswa berhasil dinonaktifkan.');
    }
}