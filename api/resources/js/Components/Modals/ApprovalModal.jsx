import React from 'react';
import { useForm } from '@inertiajs/react';
import StatusBadge from '@/Components/UI/StatusBadge';

const UserCheckIcon = ({ className = 'h-7 w-7' }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8">
        <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 7.5a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.5 20.25a7.5 7.5 0 0 1 10.5-6.87" />
        <path strokeLinecap="round" strokeLinejoin="round" d="m16.5 18 2.25 2.25L22.5 15" />
    </svg>
);

const getInitials = (name = '') => {
    const parts = name.trim().split(/\s+/).filter(Boolean);
    if (parts.length === 0) return 'P';

    return parts
        .slice(0, 2)
        .map((part) => part.charAt(0).toUpperCase())
        .join('');
};

export default function ApprovalModal({ isOpen, onClose, application }) {
    const { post, processing } = useForm();

    if (!isOpen || !application) return null;

    const handleApprove = (e) => {
        e.preventDefault();
        post(`/admin/approvals/${application.id}/approve`, {
            preserveScroll: true,
            onSuccess: () => onClose(),
        });
    };

    return (
        <div className="fixed inset-0 z-50 overflow-y-auto">
            <div className="flex min-h-screen items-center justify-center px-4 py-8">
                <button
                    type="button"
                    className="fixed inset-0 bg-gray-900/50 backdrop-blur-sm"
                    aria-label="Tutup modal"
                    onClick={onClose}
                />

                <form
                    onSubmit={handleApprove}
                    className="relative w-full max-w-md rounded-2xl bg-white p-6 text-center shadow-xl"
                >
                    <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-orange-50 text-[#F97316]">
                        <UserCheckIcon />
                    </div>

                    <h3 className="mt-5 text-xl font-bold text-gray-900">Konfirmasi</h3>
                    <p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-gray-500">
                        Apakah Anda yakin ingin menyetujui akun pembeli ini?
                    </p>

                    <div className="mt-6 rounded-xl border border-gray-100 bg-gray-50 p-4 text-left">
                        <div className="flex items-center gap-3">
                            {application.foto_profile ? (
                                <img
                                    src={application.foto_profile}
                                    alt={application.name}
                                    className="h-12 w-12 rounded-full object-cover"
                                />
                            ) : (
                                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-orange-100 text-sm font-bold text-orange-600">
                                    {getInitials(application.name)}
                                </div>
                            )}
                            <div className="min-w-0 flex-1">
                                <p className="truncate text-sm font-bold text-gray-900">{application.name}</p>
                                <p className="mt-0.5 truncate text-xs text-gray-500">{application.email}</p>
                            </div>
                            <StatusBadge status={application.status} />
                        </div>
                    </div>

                    <div className="mt-6 grid gap-3 sm:grid-cols-2">
                        <button
                            type="button"
                            onClick={onClose}
                            disabled={processing}
                            className="inline-flex w-full items-center justify-center rounded-lg border border-gray-200 bg-white px-4 py-3 text-sm font-semibold text-gray-700 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                            Batal
                        </button>
                        <button
                            type="submit"
                            disabled={processing}
                            className="inline-flex w-full items-center justify-center rounded-lg bg-[#F97316] px-4 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-orange-600 disabled:cursor-not-allowed disabled:opacity-70"
                        >
                            {processing ? 'Memproses...' : 'Setujui'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
