import React, { useState } from 'react';
import { Head, Link } from '@inertiajs/react';
import ApprovalModal from '@/Components/Modals/ApprovalModal';
import RejectionModal from '@/Components/Modals/RejectionModal';
import StatusBadge from '@/Components/UI/StatusBadge';
import AdminLayout from '@/Layouts/AdminLayout';

const formatDateTime = (value) => {
    if (!value) return '-';

    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'long',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    }).format(new Date(value));
};

const InfoIcon = ({ children }) => (
    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-orange-50 text-orange-500">
        {children}
    </div>
);

const Icon = ({ path, className = 'h-5 w-5' }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8">
        <path strokeLinecap="round" strokeLinejoin="round" d={path} />
    </svg>
);

const DetailItem = ({ label, value, icon }) => (
    <div className="flex gap-3">
        <InfoIcon>{icon}</InfoIcon>
        <div className="min-w-0">
            <dt className="text-xs font-semibold uppercase tracking-wide text-gray-400">{label}</dt>
            <dd className="mt-1 break-words text-sm font-semibold text-gray-900">{value || '-'}</dd>
        </div>
    </div>
);

const ToolButton = ({ label, children }) => (
    <button
        type="button"
        aria-label={label}
        title={label}
        className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-200 text-gray-500 transition hover:border-gray-300 hover:bg-gray-50 hover:text-gray-900"
    >
        {children}
    </button>
);

export default function Show({ application }) {
    const [modalType, setModalType] = useState(null);
    const isPending = application?.status === 'pending';

    return (
        <AdminLayout
            title="Detail Pendaftaran"
            description="Informasi lengkap pendaftar akun pembeli"
        >
            <Head title={`Pendaftaran - ${application?.name || 'Pembeli'}`} />

            <div className="p-6 pb-28 lg:p-8 lg:pb-28">
                <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                        <div className="text-sm font-semibold text-gray-500">
                            Persetujuan Akun Pembeli <span className="text-gray-300">/</span> <span className="text-gray-900">Detail</span>
                        </div>
                        <h1 className="mt-3 text-2xl font-bold text-gray-900">{application.name}</h1>
                        <p className="mt-1 text-sm text-gray-500">Detail verifikasi permintaan pendaftaran akun pembeli.</p>
                    </div>
                </div>

                <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <Link
                        href="/admin/approvals"
                        className="inline-flex w-fit items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm transition hover:bg-gray-50"
                    >
                        &larr; Kembali ke daftar pengajuan
                    </Link>
                    <StatusBadge status={application.status} />
                </div>

                <div className="grid gap-6 xl:grid-cols-[0.85fr_1.35fr]">
                    <section className="rounded-xl border border-gray-100 bg-white shadow-sm">
                        <div className="border-b border-gray-100 px-6 py-5">
                            <h2 className="text-lg font-bold text-gray-900">Informasi Pengajuan</h2>
                            <p className="mt-1 text-sm text-gray-500">Data pembeli yang akan diverifikasi.</p>
                        </div>

                        <div className="px-6 py-6">
                            <dl className="space-y-5">
                                <DetailItem
                                    label="Nama Lengkap"
                                    value={application.name}
                                    icon={<Icon path="M15.75 7.5a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.5 20.25a7.5 7.5 0 0 1 15 0" />}
                                />
                                <DetailItem
                                    label="NIM"
                                    value={application.nim}
                                    icon={<Icon path="M7.5 4.5h9m-9 5.25h9m-9 5.25h5.25M5.25 3h13.5A1.5 1.5 0 0 1 20.25 4.5v15a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-15A1.5 1.5 0 0 1 5.25 3Z" />}
                                />
                                <DetailItem
                                    label="Nomor Telepon"
                                    value={application.phone}
                                    icon={<Icon path="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106a1.125 1.125 0 0 0-1.173.417l-.97 1.293a1.125 1.125 0 0 1-1.21.38 12.035 12.035 0 0 1-7.143-7.143 1.125 1.125 0 0 1 .38-1.21l1.293-.97a1.125 1.125 0 0 0 .417-1.173L6.963 3.102A1.125 1.125 0 0 0 5.872 2.25H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25Z" />}
                                />
                                <DetailItem
                                    label="Email"
                                    value={application.email}
                                    icon={<Icon path="M21.75 6.75v10.5A2.25 2.25 0 0 1 19.5 19.5h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0-9.75 6.75L2.25 6.75" />}
                                />
                            </dl>

                            <div className="mt-6">
                                <label htmlFor="masa-berlaku" className="text-xs font-semibold uppercase tracking-wide text-gray-400">
                                    Masa Berlaku Akun
                                </label>
                                <input
                                    id="masa-berlaku"
                                    type="text"
                                    value={formatDateTime(application.updated_at)}
                                    readOnly
                                    className="mt-2 w-full rounded-lg border-gray-200 bg-gray-50 text-sm font-semibold text-gray-900 shadow-none focus:border-orange-500 focus:ring-orange-500"
                                />
                            </div>

                            <div className="mt-8 border-t border-gray-100 pt-6">
                                <div className="relative space-y-6 before:absolute before:left-[11px] before:top-2 before:h-[calc(100%-16px)] before:w-px before:bg-gray-200">
                                    <div className="relative flex gap-4">
                                        <span className="mt-1 h-6 w-6 rounded-full border-4 border-orange-100 bg-orange-500" />
                                        <div>
                                            <p className="text-sm font-semibold text-gray-900">Pengajuan Dikirim</p>
                                            <p className="mt-1 text-xs text-gray-500">{formatDateTime(application.created_at)}</p>
                                        </div>
                                    </div>
                                    <div className="relative flex gap-4">
                                        <span className="mt-1 h-6 w-6 rounded-full border-4 border-gray-100 bg-gray-300" />
                                        <div>
                                            <p className="text-sm font-semibold text-gray-900">Menunggu Persetujuan Admin</p>
                                            <p className="mt-1 text-xs text-gray-500">Status saat ini sedang diproses.</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>

                    <section className="rounded-xl border border-gray-100 bg-white shadow-sm">
                        <div className="flex flex-col gap-3 border-b border-gray-100 px-6 py-5 sm:flex-row sm:items-center sm:justify-between">
                            <div>
                                <h2 className="text-lg font-bold text-gray-900">Foto KTM</h2>
                                <p className="mt-1 text-sm text-gray-500">Periksa kecocokan identitas pembeli.</p>
                            </div>
                            <div className="flex items-center gap-2">
                                <ToolButton label="Zoom">
                                    <Icon path="M21 21l-4.35-4.35m0 0A7.5 7.5 0 1 0 6.05 6.05a7.5 7.5 0 0 0 10.6 10.6ZM10.5 7.5v6m3-3h-6" className="h-4 w-4" />
                                </ToolButton>
                                <ToolButton label="Rotate">
                                    <Icon path="M3 12a9 9 0 0 1 15.3-6.36L21 8.25M21 3v5.25h-5.25M21 12a9 9 0 0 1-15.3 6.36L3 15.75M3 21v-5.25h5.25" className="h-4 w-4" />
                                </ToolButton>
                                <ToolButton label="Reset">
                                    <Icon path="M4.5 12a7.5 7.5 0 1 1 2.196 5.304M4.5 17.25v-5.25h5.25" className="h-4 w-4" />
                                </ToolButton>
                            </div>
                        </div>

                        <div className="px-6 py-6">
                            <div className="flex aspect-[16/10] min-h-[320px] items-center justify-center rounded-xl border border-dashed border-gray-200 bg-gray-50">
                                <div className="text-center">
                                    <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-white text-gray-400 shadow-sm">
                                        <Icon path="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 7.5 12 3m0 0L7.5 7.5M12 3v13.5" className="h-7 w-7" />
                                    </div>
                                    <p className="mt-4 text-sm font-semibold text-gray-900">Foto KTM belum tersedia</p>
                                    <p className="mt-1 text-xs text-gray-500">Placeholder dokumen identitas mahasiswa.</p>
                                </div>
                            </div>

                            <div className="mt-6 rounded-xl border border-gray-100 bg-gray-50 p-5">
                                <h3 className="text-sm font-bold text-gray-900">Checklist Verifikasi KTM</h3>
                                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                                    {['Nama sesuai akun', 'NIM terbaca jelas', 'KTM masih berlaku', 'Foto tidak buram'].map((item) => (
                                        <label key={item} className="flex items-center gap-3 rounded-lg bg-white px-3 py-3 text-sm font-medium text-gray-600">
                                            <input
                                                type="checkbox"
                                                className="h-4 w-4 rounded border-gray-300 text-orange-500 focus:ring-orange-500"
                                            />
                                            {item}
                                        </label>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
            </div>

            <div className="fixed inset-x-0 bottom-0 z-30 border-t border-gray-100 bg-white/95 px-6 py-4 shadow-[0_-10px_30px_rgba(15,23,42,0.08)] backdrop-blur lg:left-64 lg:px-8">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-center gap-3 text-sm text-gray-500">
                        <span>Status saat ini</span>
                        <StatusBadge status={application.status} />
                    </div>
                    {isPending && (
                        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                            <button
                                type="button"
                                onClick={() => setModalType('reject')}
                                className="inline-flex items-center justify-center rounded-lg border border-red-200 bg-white px-5 py-2.5 text-sm font-semibold text-red-600 transition hover:bg-red-50"
                            >
                                Tolak
                            </button>
                            <button
                                type="button"
                                onClick={() => setModalType('approve')}
                                className="inline-flex items-center justify-center rounded-lg bg-[#F97316] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-orange-600"
                            >
                                Setujui Akun -&gt;
                            </button>
                        </div>
                    )}
                </div>
            </div>

            {isPending && (
                <>
                    <ApprovalModal
                        isOpen={modalType === 'approve'}
                        onClose={() => setModalType(null)}
                        application={application}
                    />
                    <RejectionModal
                        isOpen={modalType === 'reject'}
                        onClose={() => setModalType(null)}
                        application={application}
                    />
                </>
            )}
        </AdminLayout>
    );
}
