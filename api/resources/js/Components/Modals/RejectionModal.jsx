import React from 'react';
import { router } from '@inertiajs/react';

const XIcon = ({ className = 'h-5 w-5' }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8">
        <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
    </svg>
);

const WarningIcon = ({ className = 'h-5 w-5' }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8">
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v4m0 4h.01M10.29 3.86 1.82 18a2.25 2.25 0 0 0 1.93 3.38h16.5A2.25 2.25 0 0 0 22.18 18L13.71 3.86a2 2 0 0 0-3.42 0Z" />
    </svg>
);

export default function RejectionModal({ isOpen, onClose, application }) {
    const [processing, setProcessing] = React.useState(false);

    if (!isOpen || !application) return null;

    const handleReject = () => {
        router.post(`/admin/approvals/${application.id}/reject`, {}, {
            preserveScroll: true,
            onStart: () => setProcessing(true),
            onFinish: () => setProcessing(false),
            onSuccess: () => onClose(),
        });
    };

    const handleClose = () => {
        onClose();
    };

    return (
        <div className="fixed inset-0 z-50 overflow-y-auto">
            <div className="flex min-h-screen items-center justify-center px-4 py-8">
                <button
                    type="button"
                    className="fixed inset-0 bg-gray-900/50 backdrop-blur-sm"
                    aria-label="Tutup modal"
                    onClick={handleClose}
                />

                <div className="relative w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
                    <button
                        type="button"
                        onClick={handleClose}
                        disabled={processing}
                        className="absolute right-5 top-5 flex h-9 w-9 items-center justify-center rounded-full text-gray-400 transition hover:bg-gray-100 hover:text-gray-700 disabled:cursor-not-allowed disabled:opacity-60"
                        aria-label="Tutup"
                    >
                        <XIcon />
                    </button>

                    <div className="pr-10">
                        <h3 className="text-xl font-bold text-gray-900">Tolak Pengajuan</h3>
                        <p className="mt-2 text-sm leading-6 text-gray-500">
                            Akun {application.name} akan ditolak
                        </p>
                    </div>

                    <div className="mt-6 rounded-xl border border-red-100 bg-red-50 p-4">
                        <div className="flex gap-3">
                            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-red-100 text-red-600">
                                <WarningIcon />
                            </div>
                            <p className="text-sm font-semibold leading-6 text-red-700">
                                Tindakan ini akan menolak pengajuan akun pembeli dan pemohon akan menerima notifikasi penolakan.
                            </p>
                        </div>
                    </div>

                    <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                        <button
                            type="button"
                            onClick={handleClose}
                            disabled={processing}
                            className="inline-flex items-center justify-center rounded-lg border border-gray-200 bg-white px-5 py-3 text-sm font-semibold text-gray-700 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                            Batal
                        </button>
                        <button
                            type="button"
                            onClick={handleReject}
                            disabled={processing}
                            className="inline-flex items-center justify-center rounded-lg bg-red-600 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-70"
                        >
                            {processing ? 'Memproses...' : 'Tolak Akun'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
