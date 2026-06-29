<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BuyerApplication;
use App\Services\Admin\ApprovalService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;
use RuntimeException;

class BuyerApprovalController extends Controller
{
    public function __construct(private readonly ApprovalService $approvalService)
    {
    }

    public function index(Request $request): Response
    {
        $query = BuyerApplication::query()->where('status', 'pending');

        // Filter pencarian (Nama, NIM, Email)
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('nim', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $applications = $query->orderByDesc('created_at')
            ->paginate(10)
            ->withQueryString()
            ->through(fn (BuyerApplication $application) => $this->formatApplication($application));

        return Inertia::render('Approvals/Index', [
            'applications' => $applications,
            'filters' => $request->only(['search']),
        ]);
    }

    public function show(int $application): Response
    {
        $applicationData = BuyerApplication::query()->findOrFail($application);

        return Inertia::render('Approvals/Show', [
            'application' => $this->formatApplication($applicationData),
        ]);
    }

    public function approve(Request $request, int $application): RedirectResponse
    {
        try {
            $result = $this->approvalService->approve($application, $request->user()?->id);
        } catch (RuntimeException $exception) {
            return redirect()
                ->back()
                ->with('error', $exception->getMessage());
        }

        $message = "Akun {$result['user']->username} berhasil disetujui.";
        if ($result['is_default'] ?? true) {
            $message .= " Password default: {$result['default_password']}";
        } else {
            $message .= " Menggunakan password yang didaftarkan oleh mahasiswa.";
        }

        return redirect()
            ->route('admin.approvals.index')
            ->with('success', $message);
    }

    public function reject(Request $request, int $application): RedirectResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        try {
            $this->approvalService->reject($application, $validated['reason'], $request->user()?->id);
        } catch (RuntimeException $exception) {
            return redirect()
                ->back()
                ->with('error', $exception->getMessage());
        }

        return redirect()
            ->route('admin.approvals.index')
            ->with('success', 'Pendaftaran mahasiswa berhasil ditolak.');
    }

    private function formatApplication(BuyerApplication $application): array
    {
        return [
            'id' => $application->id,
            'name' => $application->name,
            'nim' => $application->nim,
            'jurusan' => $application->jurusan,
            'email' => $application->email,
            'phone' => $application->phone,
            'account_expires_at' => $application->account_expires_at,
            'ktm_photo_url' => $this->publicUrl($application->foto_ktm_path),
            'status' => $application->status,
            'rejection_reason' => $application->rejection_reason,
            'created_at' => $application->created_at,
            'updated_at' => $application->updated_at,
        ];
    }

    private function publicUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return str_starts_with($path, 'http')
            ? $path
            : Storage::disk('public')->url($path);
    }
}
