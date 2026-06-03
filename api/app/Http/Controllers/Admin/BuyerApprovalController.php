<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class BuyerApprovalController extends Controller
{
    public function index(): Response
    {
        $applications = User::query()
            ->with('mahasiswa')
            ->where('role', 'mahasiswa')
            ->orderByDesc('created_at')
            ->paginate(10)
            ->through(fn (User $user) => $this->formatApplication($user));

        return Inertia::render('Approvals/Index', [
            'applications' => $applications,
        ]);
    }

    public function show(int $application): Response
    {
        $applicationData = User::query()
            ->with('mahasiswa')
            ->where('role', 'mahasiswa')
            ->whereKey($application)
            ->firstOrFail();

        return Inertia::render('Approvals/Show', [
            'application' => $this->formatApplication($applicationData),
        ]);
    }

    private function formatApplication(User $application): array
    {
        return [
            'id' => $application->id,
            'name' => $application->username,
            'nim' => $application->mahasiswa?->nim ?? '-',
            'email' => $application->email,
            'phone' => $application->mahasiswa?->no_telp ?? '-',
            'major' => $application->mahasiswa?->major
                ?? $application->mahasiswa?->program_studi
                ?? $application->mahasiswa?->jurusan
                ?? '-',
            'status' => $application->status_akun,
            'raw_status' => $application->status_akun,
            'created_at' => optional($application->created_at)->toISOString(),
            'updated_at' => optional($application->updated_at)->toISOString(),
        ];
    }

    public function approve(int $application): RedirectResponse
    {
        $user = User::where('role', 'mahasiswa')->findOrFail($application);
        $user->update(['status_akun' => 'aktif']);

        return redirect()
            ->back()
            ->with('success', "Pendaftaran {$user->username} berhasil disetujui.");
    }

    public function reject(Request $request, int $application): RedirectResponse
    {
        $request->validate([
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $user = User::where('role', 'mahasiswa')->findOrFail($application);
        $user->update(['status_akun' => 'ditolak']);

        return redirect()
            ->back()
            ->with('success', 'Pendaftaran mahasiswa berhasil ditolak.');
    }
}
