<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\ApprovalService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class BuyerApprovalController extends Controller
{
    protected $approvalService;

    // Injeksi ApprovalService ke controller (Service Pattern)
    public function __construct(ApprovalService $approvalService)
    {
        $this->approvalService = $approvalService;
    }

    /**
     * Menampilkan daftar aplikasi pendaftaran mahasiswa yang menunggu (pending).
     */
    public function index()
    {
        // Mengambil data pendaftar yang belum disetujui.
        // Asumsi tabel bernama `buyer_applications`.
        $applications = DB::table('buyer_applications')
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return Inertia::render('Approvals/Index', [
            'applications' => $applications
        ]);
    }

    /**
     * Menampilkan halaman detail untuk satu pendaftaran tertentu.
     */
    public function show($id)
    {
        $application = DB::table('buyer_applications')->find($id);

        if (!$application) {
            abort(404, 'Application not found');
        }

        return Inertia::render('Approvals/Show', [
            'application' => $application
        ]);
    }

    /**
     * Aksi untuk menyetujui pendaftaran.
     * Mendelegasikan proses logika utama (transfer data & Firestore) ke service.
     */
    public function approve(Request $request, $id)
    {
        $application = DB::table('buyer_applications')->find($id);

        if (!$application || $application->status !== 'pending') {
            return redirect()->back()->with('error', 'Invalid or already processed application.');
        }

        try {
            // Panggil business logic
            $this->approvalService->approve($application);
            return redirect()->back()->with('success', 'Application approved successfully.');
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to approve application: ' . $e->getMessage());
        }
    }

    /**
     * Aksi untuk menolak pendaftaran.
     * Mendelegasikan proses update status dan alasan ke service.
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'reason' => 'required|string|max:255',
        ]);

        $application = DB::table('buyer_applications')->find($id);

        if (!$application || $application->status !== 'pending') {
            return redirect()->back()->with('error', 'Invalid or already processed application.');
        }

        try {
            // Panggil business logic
            $this->approvalService->reject($application, $request->reason);
            return redirect()->back()->with('success', 'Application rejected.');
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to reject application: ' . $e->getMessage());
        }
    }
}
