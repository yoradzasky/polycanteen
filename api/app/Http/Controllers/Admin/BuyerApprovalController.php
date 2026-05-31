<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Admin\ApprovalService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

class BuyerApprovalController extends Controller
{
    public function __construct(private readonly ApprovalService $approvalService)
    {
    }

    public function approve(int $application): RedirectResponse
    {
        try {
            $user = $this->approvalService->approve($application);

            return redirect()
                ->back()
                ->with('success', "Pendaftaran {$user->username} berhasil disetujui. Password default: {$this->approvalService->defaultPassword()}");
        } catch (ModelNotFoundException|RuntimeException $exception) {
            return redirect()
                ->back()
                ->with('error', $exception->getMessage());
        } catch (Throwable $exception) {
            Log::error('Failed to approve buyer application.', [
                'application_id' => $application,
                'exception' => $exception,
            ]);

            return redirect()
                ->back()
                ->with('error', 'Gagal menyetujui pendaftaran mahasiswa. Silakan coba lagi.');
        }
    }

    public function reject(int $application): RedirectResponse
    {
        try {
            $this->approvalService->reject($application);

            return redirect()
                ->back()
                ->with('success', 'Pendaftaran mahasiswa berhasil ditolak.');
        } catch (ModelNotFoundException|RuntimeException $exception) {
            return redirect()
                ->back()
                ->with('error', $exception->getMessage());
        } catch (Throwable $exception) {
            Log::error('Failed to reject buyer application.', [
                'application_id' => $application,
                'exception' => $exception,
            ]);

            return redirect()
                ->back()
                ->with('error', 'Gagal menolak pendaftaran mahasiswa. Silakan coba lagi.');
        }
    }
}
