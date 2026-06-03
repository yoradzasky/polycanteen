import React, { useMemo, useState } from 'react';
import { Head, Link } from '@inertiajs/react';
import StatusBadge from '@/Components/UI/StatusBadge';
import AdminLayout from '@/Layouts/AdminLayout';

const FILTERS = [
    { label: 'Semua', value: 'all' },
    { label: 'Pending', value: 'pending' },
    { label: 'Disetujui', value: 'aktif' },
    { label: 'Ditolak', value: 'ditolak' },
];

const formatDate = (value) => {
    if (!value) return '-';

    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
    }).format(new Date(value));
};

const getInitials = (name = '') => {
    const parts = name.trim().split(/\s+/).filter(Boolean);
    if (parts.length === 0) return 'P';

    return parts
        .slice(0, 2)
        .map((part) => part.charAt(0).toUpperCase())
        .join('');
};

const EyeIcon = ({ className = 'h-4 w-4' }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8">
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12s3.5-6.75 9.75-6.75S21.75 12 21.75 12s-3.5 6.75-9.75 6.75S2.25 12 2.25 12Z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
    </svg>
);

const ExportIcon = ({ className = 'h-4 w-4' }) => (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8">
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v12m0 0 4-4m-4 4-4-4" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 15.75v2.25A3 3 0 0 0 7.5 21h9a3 3 0 0 0 3-3v-2.25" />
    </svg>
);

export default function Index({ applications }) {
    const [activeFilter, setActiveFilter] = useState('all');
    const data = useMemo(() => applications?.data || [], [applications]);
    const filteredData = useMemo(() => {
        if (activeFilter === 'all') return data;

        return data.filter((application) => application.status === activeFilter);
    }, [activeFilter, data]);

    return (
        <AdminLayout
            title="Persetujuan Akun"
            description="Kelola permintaan pendaftaran akun pembeli"
        >
            <Head title="Persetujuan Akun Pembeli" />

            <div className="p-6 lg:p-8">
                <div className="mb-7">
                    <h1 className="text-2xl font-bold text-gray-900">Persetujuan Akun Pembeli</h1>
                    <p className="mt-1 text-sm text-gray-500">Kelola permintaan pendaftaran akun pembeli</p>
                </div>

                <div className="rounded-xl border border-gray-100 bg-white shadow-sm">
                    <div className="flex flex-col gap-4 border-b border-gray-100 px-6 py-5 xl:flex-row xl:items-center xl:justify-between">
                        <div>
                            <h2 className="text-lg font-semibold text-gray-900">Daftar Permintaan Pendaftaran</h2>
                            <p className="mt-1 text-sm text-gray-500">
                                Total {applications?.total || 0} permintaan
                            </p>
                        </div>

                        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                            <div className="flex flex-wrap items-center gap-1 rounded-full bg-gray-50 p-1">
                                {FILTERS.map((filter) => {
                                    const isActive = activeFilter === filter.value;

                                    return (
                                        <button
                                            key={filter.value}
                                            type="button"
                                            onClick={() => setActiveFilter(filter.value)}
                                            className={`rounded-full px-4 py-2 text-sm font-semibold transition ${
                                                isActive
                                                    ? 'bg-[#F97316] text-white shadow-sm'
                                                    : 'text-gray-500 hover:text-gray-900'
                                            }`}
                                        >
                                            {filter.label}
                                        </button>
                                    );
                                })}
                            </div>

                            <button
                                type="button"
                                className="inline-flex items-center justify-center gap-2 rounded-full border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm transition hover:border-gray-300 hover:bg-gray-50"
                            >
                                <ExportIcon />
                                Export
                            </button>
                        </div>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[980px] text-left text-sm">
                            <thead className="border-b border-gray-100 bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
                                <tr>
                                    <th className="px-6 py-4 font-semibold">Nama Pembeli</th>
                                    <th className="px-6 py-4 font-semibold">No HP</th>
                                    <th className="px-6 py-4 font-semibold">Tanggal Daftar</th>
                                    <th className="px-6 py-4 font-semibold">Status</th>
                                    <th className="px-6 py-4 font-semibold">Detail</th>
                                    <th className="px-6 py-4 font-semibold">Aksi</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 bg-white">
                                {filteredData.map((application) => (
                                    <tr key={application.id} className="transition hover:bg-gray-50/80">
                                        <td className="px-6 py-5">
                                            <div className="flex items-center gap-3">
                                                {application.foto_profile ? (
                                                    <img
                                                        src={application.foto_profile}
                                                        alt={application.name}
                                                        className="h-11 w-11 rounded-full object-cover"
                                                    />
                                                ) : (
                                                    <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-orange-100 text-sm font-bold text-orange-600">
                                                        {getInitials(application.name)}
                                                    </div>
                                                )}
                                                <div className="min-w-0">
                                                    <div className="truncate font-semibold text-gray-900">{application.name}</div>
                                                    <div className="mt-0.5 text-xs text-gray-500">ID/NIM: {application.nim || '-'}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-5 text-gray-600">{application.phone || '-'}</td>
                                        <td className="px-6 py-5 text-gray-600">{formatDate(application.created_at)}</td>
                                        <td className="px-6 py-5">
                                            <StatusBadge status={application.status} />
                                        </td>
                                        <td className="px-6 py-5">
                                            <div className="max-w-[220px] truncate text-gray-600">{application.email || '-'}</div>
                                        </td>
                                        <td className="px-6 py-5">
                                            <Link
                                                href={`/admin/approvals/${application.id}`}
                                                className="inline-flex items-center justify-center gap-2 rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
                                            >
                                                <EyeIcon />
                                                Detail
                                            </Link>
                                        </td>
                                    </tr>
                                ))}

                                {filteredData.length === 0 && (
                                    <tr>
                                        <td colSpan="6" className="px-6 py-14 text-center text-sm text-gray-500">
                                            Belum ada permintaan pendaftaran.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>

                    <div className="flex flex-col gap-3 border-t border-gray-100 px-6 py-4 sm:flex-row sm:items-center sm:justify-between">
                        <p className="text-sm text-gray-500">
                            Showing {applications?.from || 0}-{applications?.to || 0} of {applications?.total || 0} permintaan
                        </p>
                        {applications?.links?.length > 3 && (
                            <div className="flex flex-wrap items-center gap-1">
                                {applications.links.map((link) => (
                                    <Link
                                        key={link.label}
                                        href={link.url || '#'}
                                        preserveScroll
                                        className={`min-w-9 rounded-lg px-3 py-2 text-center text-sm font-semibold transition ${
                                            link.active
                                                ? 'bg-[#F97316] text-white shadow-sm'
                                                : link.url
                                                    ? 'text-gray-600 hover:bg-gray-100'
                                                    : 'pointer-events-none text-gray-300'
                                        }`}
                                        dangerouslySetInnerHTML={{ __html: link.label }}
                                    />
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
}
