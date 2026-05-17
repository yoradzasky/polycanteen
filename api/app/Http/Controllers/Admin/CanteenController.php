<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\CanteenService;
use Illuminate\Http\Request;
use Inertia\Inertia;

class CanteenController extends Controller
{
    // MENGAPA: Dependency Injection service di controller menggunakan 
    // properti readonly sesuai arsitektur Laravel modern / standar OOP yang bersih. (Aturan 9)
    public function __construct(private readonly CanteenService $canteenService)
    {
    }

    /**
     * Menampilkan daftar semua kantin.
     */
    public function index()
    {
        // MENGAPA: Thin Controller, controller hanya bertugas memanggil service 
        // dan tidak berisi query DB sama sekali. (Aturan 1 & 20)
        $response = $this->canteenService->getAllCanteens();

        if (!$response['success']) {
            // MENGAPA: Jika Service mengembalikan false, Controller WAJIB 
            // melakukan redirect back dengan flash message error. BUKAN melempar prop. (Aturan 21)
            return redirect()->back()->with('error', $response['message']);
        }

        // MENGAPA: Controller bertugas langsung return view menggunakan Inertia
        // Data dari Service diteruskan ke Props React.
        return Inertia::render('Canteens/Index', [
            'canteens' => $response['data']
        ]);
    }

    /**
     * Menampilkan halaman formulir pembuatan kantin.
     */
    public function create()
    {
        return Inertia::render('Canteens/Create');
    }

    /**
     * Menyimpan data kantin dari form.
     */
    public function store(Request $request)
    {
        // MENGAPA: Validasi diletakkan di layer Controller (atau FormRequest)
        // sebelum menyentuh layer Service untuk memastikan data steril. (Aturan 1)
        $validated = $request->validate([
            'nama_kantin' => 'required|string|max:255',
            'lokasi_lengkap' => 'nullable|string|max:500',
            'nama_pemilik' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'nim' => 'required|string|min:5|max:20', // Akan digunakan sbg password akun pemilik
            'no_telp' => 'nullable|string|max:20',
        ]);

        // MENGAPA: Pemanggilan satu method dari Service yang berisi seluruh logika bisnis 
        // (Transaksi DB, pembuatan relasi, sinkronisasi Firestore) (Aturan 2)
        $response = $this->canteenService->createCanteen($validated);

        if (!$response['success']) {
            // MENGAPA: Jika service mereturn false, redirect back beserta pesan error flash (Aturan 21)
            return redirect()->back()->with('error', $response['message']);
        }

        // MENGAPA: Redirect ke halaman daftar menggunakan Inertia dengan membawa flash message sukses
        return redirect()->route('admin.canteens.index')->with('success', $response['message']);
    }
}
