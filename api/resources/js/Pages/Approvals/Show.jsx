import React, { useMemo, useState } from 'react';
import { Head, Link } from '@inertiajs/react';
import AdminLayout from '@/Layouts/AdminLayout';
import ApprovalModal from '@/Components/Modals/ApprovalModal';
import RejectionModal from '@/Components/Modals/RejectionModal';
import StatusBadge from '@/Components/UI/StatusBadge';

const statusStyles = {
    pending: 'bg-amber-50 text-amber-700 ring-amber-200',
    approved: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
    rejected: 'bg-red-50 text-red-700 ring-red-200',
};

function formatDate(value) {
    if (!value) return '-';

    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'long',
        year: 'numeric',
    }).format(new Date(value));
}

export default function Show({ application }) {
    const [approvalOpen, setApprovalOpen] = useState(false);
    const [rejectionOpen, setRejectionOpen] = useState(false);

    const data = application || {};
    const isPending = data.status === 'pending';

    const detailItems = useMemo(() => ([
        { label: 'Nama', value: data.name },
        { label: 'NIM', value: data.nim },
        { label: 'Jurusan', value: data.jurusan || '-' },
        { label: 'No. Telepon', value: data.phone || '-' },
        { label: 'Email', value: data.email },
        { label: 'Masa Berlaku Akun', value: formatDate(data.account_expires_at) },
    ]), [data]);

    const breadcrumb = (
        <div className="flex items-center gap-2 text-sm font-medium">
            <Link href="/admin/approvals" className="text-[#3852b4] hover:underline">
                Persetujuan Akun
            </Link>
            <span className="text-gray-400">›</span>
            <span className="text-gray-500">Detail Pengajuan</span>
        </div>
    );

    const backButton = (
        <Link
            href="/admin/approvals"
            className="-ml-1 rounded-lg p-1 text-gray-400 transition hover:bg-white hover:text-[#3852b4]"
            title="Kembali"
        >
            <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7" />
            </svg>
        </Link>
    );

    return (
        <AdminLayout leftContent={backButton} title="Detail Pengajuan" description={breadcrumb}>
            <Head title={`Detail Pengajuan - ${data.name || 'Mahasiswa'}`} />

            <div className="p-6 lg:p-8 font-sans pb-20 w-full">
                <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_420px]">
                    <section className="rounded-xl border border-gray-100 bg-white p-6 shadow-sm">
                        <div className="mb-6 flex flex-col gap-3 border-b border-gray-100 pb-5 sm:flex-row sm:items-start sm:justify-between">
                            <div>
                                <h2 className="text-xl font-bold text-gray-900">{data.name}</h2>
                                <p className="mt-1 text-sm text-gray-500">Pengajuan akun pembeli mahasiswa.</p>
                            </div>
                            <StatusBadge status={data.status} />
                        </div>

                        <div className="grid gap-4 sm:grid-cols-2">
                            {detailItems.map((item) => (
                                <div key={item.label} className="rounded-xl border border-gray-100 bg-gray-50 px-4 py-3">
                                    <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">{item.label}</p>
                                    <p className="mt-1 break-words text-sm font-semibold text-gray-900">{item.value || '-'}</p>
                                </div>
                            ))}
                        </div>

                        {data.rejection_reason && (
                            <div className="mt-5 rounded-xl border border-red-100 bg-red-50 px-4 py-3">
                                <p className="text-xs font-semibold uppercase tracking-wide text-red-400">Alasan Penolakan</p>
                                <p className="mt-1 text-sm text-red-700">{data.rejection_reason}</p>
                            </div>
                        )}

                        <div className="mt-6 flex flex-col-reverse gap-3 border-t border-gray-100 pt-5 sm:flex-row sm:justify-end">
                            <button
                                type="button"
                                onClick={() => setRejectionOpen(true)}
                                disabled={!isPending}
                                className="inline-flex items-center justify-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-bold text-red-600 transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M6 18L18 6M6 6l12 12" />
                                </svg>
                                Tolak Pengajuan
                            </button>
                            <button
                                type="button"
                                onClick={() => setApprovalOpen(true)}
                                disabled={!isPending}
                                className="inline-flex items-center justify-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-2.5 text-sm font-bold text-green-600 shadow-sm transition hover:bg-green-100 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M5 13l4 4L19 7" />
                                </svg>
                                Setujui Akun
                            </button>
                        </div>
                    </section>

                    <aside className="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
                        <div className="mb-4">
                            <h3 className="text-base font-bold text-gray-900">Foto KTM</h3>
                            <p className="mt-1 text-sm text-gray-500">Gunakan preview ini untuk mencocokkan identitas mahasiswa.</p>
                        </div>

                        <div className="flex aspect-[4/3] items-center justify-center overflow-hidden rounded-xl border border-gray-200 bg-gray-50">
                            {data.ktm_photo_url ? (
                                <img
                                    src={data.ktm_photo_url}
                                    alt={`Foto KTM ${data.name}`}
                                    className="h-full w-full object-contain"
                                />
                            ) : (
                                <div className="px-6 text-center">
                                    <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 text-gray-400">
                                        <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 7h18M5 7v10a2 2 0 002 2h10a2 2 0 002-2V7M9 11h6M9 15h3" />
                                        </svg>
                                    </div>
                                    <p className="text-sm font-medium text-gray-500">Foto KTM belum tersedia</p>
                                </div>
                            )}
                        </div>
                    </aside>
                </div>
            </div>

            <ApprovalModal
                isOpen={approvalOpen}
                onClose={() => setApprovalOpen(false)}
                application={data}
            />
            <RejectionModal
                isOpen={rejectionOpen}
                onClose={() => setRejectionOpen(false)}
                application={data}
            />
        </AdminLayout>
    );
}
