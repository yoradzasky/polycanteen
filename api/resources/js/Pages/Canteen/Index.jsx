import AdminLayout from '@/Layouts/AdminLayout';
import { Head, Link, router } from '@inertiajs/react';
import { useState, useEffect, useRef } from 'react';
import DeleteConfirmModal from '@/Components/Modals/DeleteConfirmModal';

// ── Helper Functions ──────────────────────────────────────────────

function formatRupiah(angka) {
    if (!angka && angka !== 0) return 'Rp 0';
    if (angka >= 1_000_000_000) {
        const val = angka / 1_000_000_000;
        return `Rp ${val % 1 === 0 ? val : val.toFixed(1).replace('.', ',')} M`;
    }
    if (angka >= 1_000_000) {
        const val = angka / 1_000_000;
        return `Rp ${val % 1 === 0 ? val : val.toFixed(1).replace('.', ',')} jt`;
    }
    if (angka >= 1_000) {
        const val = angka / 1_000;
        return `Rp ${val % 1 === 0 ? val : val.toFixed(1).replace('.', ',')} rb`;
    }
    return `Rp ${angka.toLocaleString('id-ID')}`;
}

function formatTanggal(isoString) {
    if (!isoString) return '-';
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    const d = new Date(isoString);
    return `${d.getDate()} ${bulan[d.getMonth()]} ${d.getFullYear()}`;
}

function getInisial(nama) {
    if (!nama) return '?';
    return nama
        .split(' ')
        .filter(Boolean)
        .map((w) => w[0])
        .slice(0, 2)
        .join('')
        .toUpperCase();
}

// ── Avatar Component ──────────────────────────────────────────────

function Avatar({ src, nama, size = 'w-8 h-8', textSize = 'text-xs' }) {
    const inisial = getInisial(nama);
    const colors = [
        'bg-blue-500', 'bg-emerald-500', 'bg-orange-500', 'bg-purple-500',
        'bg-pink-500', 'bg-teal-500', 'bg-indigo-500', 'bg-rose-500',
    ];
    const colorIndex = (nama || '').split('').reduce((acc, c) => acc + c.charCodeAt(0), 0) % colors.length;

    if (src) {
        return (
            <img
                src={src}
                alt={nama}
                className={`${size} rounded-full object-cover ring-2 ring-white flex-shrink-0`}
            />
        );
    }
    return (
        <div className={`${size} ${colors[colorIndex]} rounded-full flex items-center justify-center ring-2 ring-white flex-shrink-0`}>
            <span className={`${textSize} font-semibold text-white`}>{inisial}</span>
        </div>
    );
}

// ── Status Badge ──────────────────────────────────────────────────

function StatusBadge({ status }) {
    const isBuka = status === 'buka';
    return (
        <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${isBuka
                ? 'bg-emerald-50 text-emerald-600'
                : 'bg-gray-100 text-gray-500'
            }`}>
            <span className={`w-1.5 h-1.5 rounded-full ${isBuka ? 'bg-emerald-500' : 'bg-gray-400'}`} />
            {isBuka ? 'Buka' : 'Tutup'}
        </span>
    );
}

// ── Action Buttons ────────────────────────────────────────────────

function ActionButtons({ canteen, onShowDelete }) {
    return (
        <div className="flex items-center gap-2">
            <Link
                href={route('admin.canteens.show', canteen.id)}
                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
            >
                {/* Eye icon */}
                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                Detail
            </Link>
            <Link
                href={route('admin.canteens.edit', { id: canteen.id, from: 'index' })}
                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-orange-600 bg-orange-50 rounded-lg hover:bg-orange-100 transition-colors"
            >
                {/* Pencil icon */}
                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                </svg>
                Edit
            </Link>
            <button
                onClick={() => onShowDelete({ id: canteen.id, nama_kantin: canteen.nama_kantin, logo_path: canteen.logo_path })}
                className="inline-flex items-center justify-center w-8 h-8 text-[#EF4444] bg-red-50 rounded-lg hover:bg-red-100 hover:text-red-600 transition-colors"
                title="Hapus Kantin"
            >
                {/* Ban / Stop icon */}
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                </svg>
            </button>
        </div>
    );
}

// ── Pagination Component ──────────────────────────────────────────

function Pagination({ links }) {
    if (!links || links.length <= 3) return null;

    return (
        <nav className="flex items-center gap-1" aria-label="Paginasi">
            {links.map((link, i) => {
                if (!link.url && !link.active) {
                    // Disabled prev/next or ellipsis
                    if (link.label === '...') {
                        return (
                            <span key={i} className="px-2 py-1 text-sm text-gray-400">
                                …
                            </span>
                        );
                    }
                    return (
                        <span
                            key={i}
                            className="flex items-center justify-center min-w-[32px] h-8 px-2 text-sm text-gray-300 rounded-lg"
                            dangerouslySetInnerHTML={{ __html: link.label }}
                        />
                    );
                }

                return (
                    <Link
                        key={i}
                        href={link.url || '#'}
                        preserveState
                        className={`flex items-center justify-center min-w-[32px] h-8 px-2 text-sm rounded-lg transition-colors ${link.active
                                ? 'bg-[#3852b4] text-white font-semibold shadow-sm'
                                : 'text-gray-600 hover:bg-gray-100'
                            }`}
                        dangerouslySetInnerHTML={{ __html: link.label }}
                    />
                );
            })}
        </nav>
    );
}

// ── Main Component ────────────────────────────────────────────────

export default function Index({ canteens, filters }) {
    const [search, setSearch] = useState(filters.nama_kantin || '');
    const [perPage, setPerPage] = useState(canteens.per_page || 8);
    const [deleteTarget, setDeleteTarget] = useState(null); // { id, nama_kantin, logo_path }
    const [isDeleting, setIsDeleting]     = useState(false);
    const debounceTimer = useRef(null);

    // Debounced search
    useEffect(() => {
        if (debounceTimer.current) clearTimeout(debounceTimer.current);

        debounceTimer.current = setTimeout(() => {
            router.get(
                route('admin.canteens.index'),
                { nama_kantin: search, per_page: perPage },
                { preserveState: true, replace: true }
            );
        }, 500);

        return () => clearTimeout(debounceTimer.current);
    }, [search]);

    const handlePerPageChange = (e) => {
        const value = parseInt(e.target.value);
        setPerPage(value);
        router.get(
            route('admin.canteens.index'),
            { nama_kantin: search, per_page: value },
            { preserveState: true, replace: true }
        );
    };

    const meta = canteens;

    return (
        <AdminLayout
            title="Daftar Kantin"
            description="Kelola seluruh kantin yang terdaftar"
            rightContent={
                <div className="flex items-center gap-3">
                    {/* Search */}
                    <div className="relative">
                        <svg
                            className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400"
                            fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                        <input
                            type="text"
                            placeholder="Cari kantin..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            className="pl-9 pr-4 py-2.5 w-56 bg-[#f4f6fb] border border-gray-100 rounded-xl text-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#3852b4]/30 focus:border-[#3852b4]/40 transition-all"
                        />
                    </div>
                    {/* Add Button */}
                    <Link
                        href={route('admin.canteens.create')}
                        className="inline-flex items-center gap-2 px-5 py-2.5 bg-[#3852b4] hover:bg-[#2c4190] text-white text-sm font-semibold rounded-xl shadow-sm hover:shadow-md transition-all"
                    >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                        Tambah Kantin
                    </Link>
                </div>
            }
        >
            <Head title="Daftar Kantin" />

            <div className="p-6 lg:p-8 font-sans pb-20 w-full">
                {/* ── Table Card ── */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                    {/* Card Header */}
                    <div className="px-6 py-5 border-b border-gray-200">
                        <h2 className="text-base font-bold text-gray-900">Daftar Semua Kantin</h2>
                        <p className="text-xs text-gray-400 mt-0.5">
                            Menampilkan {canteens.data?.length || 0} dari {meta.total || 0} kantin
                        </p>
                    </div>

                    {/* Table */}
                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[900px]">
                            <thead>
                                <tr className="border-b-2 border-gray-300">
                                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Nama Kantin</th>
                                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Pemilik</th>
                                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Lokasi</th>
                                    <th className="text-center px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Jumlah Menu</th>
                                    <th className="text-right px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Transaksi</th>
                                    <th className="text-center px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                                    <th className="text-left px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Tanggal Daftar</th>
                                    <th className="text-center px-6 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wider">Aksi</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y-2 divide-gray-200">
                                {canteens.data && canteens.data.length > 0 ? (
                                    canteens.data.map((kantin) => (
                                        <tr key={kantin.id} className="hover:bg-[#f9fafd] transition-colors">
                                            {/* Nama Kantin */}
                                            <td className="px-6 py-4 text-left">
                                                <div className="flex items-center gap-3">
                                                    <div className="flex-shrink-0">
                                                        <Avatar src={kantin.logo_path ? (kantin.logo_path.startsWith('http') ? kantin.logo_path : `/storage/${kantin.logo_path}`) : null} nama={kantin.nama_kantin} size="w-9 h-9" textSize="text-xs" />
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-semibold text-gray-900 line-clamp-2">{kantin.nama_kantin}</p>
                                                    </div>
                                                </div>
                                            </td>
                                            {/* Pemilik */}
                                            <td className="px-6 py-4 text-left">
                                                <div className="flex items-center gap-2.5">
                                                    <div className="flex-shrink-0">
                                                        <Avatar
                                                            src={kantin.pemilik?.foto_profil_path ? (kantin.pemilik.foto_profil_path.startsWith('http') ? kantin.pemilik.foto_profil_path : `/storage/${kantin.pemilik.foto_profil_path}`) : null}
                                                            nama={kantin.pemilik?.nama_pemilik}
                                                            size="w-7 h-7"
                                                            textSize="text-[10px]"
                                                        />
                                                    </div>
                                                    <span className="text-sm text-gray-700 line-clamp-2">{kantin.pemilik?.nama_pemilik || '-'}</span>
                                                </div>
                                            </td>
                                            {/* Lokasi */}
                                            <td className="px-6 py-4 text-left max-w-[200px]">
                                                <div className="flex items-start gap-1.5">
                                                    <svg className="w-3.5 h-3.5 text-emerald-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                                                        <path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd" />
                                                    </svg>
                                                    <span className="text-sm text-gray-600 line-clamp-2">{kantin.lokasi_lengkap || '-'}</span>
                                                </div>
                                            </td>
                                            {/* Jumlah Menu */}
                                            <td className="px-6 py-4 text-center">
                                                <span className="text-sm font-medium text-gray-700">
                                                    {kantin.menus_count ?? 0}
                                                    <span className="text-gray-400 font-normal ml-1">menu</span>
                                                </span>
                                            </td>
                                            {/* Total Transaksi */}
                                            <td className="px-6 py-4 text-right">
                                                <p className="text-sm font-semibold text-gray-900">
                                                    {formatRupiah(kantin.pesanan_sum_total_harga || 0)}
                                                </p>
                                            </td>
                                            {/* Status */}
                                            <td className="px-6 py-4 text-center">
                                                <StatusBadge status={kantin.status_toko} />
                                            </td>
                                            {/* Tanggal Daftar */}
                                            <td className="px-6 py-4 text-left">
                                                <span className="text-sm text-gray-600 whitespace-nowrap">{formatTanggal(kantin.created_at)}</span>
                                            </td>
                                            {/* Aksi */}
                                            <td className="px-6 py-4 text-center">
                                                <ActionButtons canteen={kantin} onShowDelete={setDeleteTarget} />
                                            </td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td colSpan={8} className="px-6 py-16 text-center">
                                            <div className="flex flex-col items-center gap-2">
                                                <svg className="w-12 h-12 text-gray-200" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
                                                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                                                </svg>
                                                <p className="text-sm text-gray-400">Belum ada data kantin</p>
                                            </div>
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>

                    {/* ── Footer: Info + Pagination ── */}
                    <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
                        {/* Left: Info */}
                        <p className="text-sm text-gray-500">
                            Menampilkan{' '}
                            <span className="font-semibold text-gray-700">{meta.from || 0}–{meta.to || 0}</span>
                            {' '}dari{' '}
                            <span className="font-semibold text-gray-700">{meta.total || 0}</span>
                            {' '}kantin
                        </p>

                        {/* Center: Pagination */}
                        <Pagination links={canteens.links} />

                        {/* Right: Per page */}
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                            <span>Baris per halaman:</span>
                            <select
                                value={perPage}
                                onChange={handlePerPageChange}
                                className="bg-white border border-gray-200 rounded-lg px-2 py-1 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#3852b4]/30 focus:border-[#3852b4]/40 cursor-pointer"
                            >
                                <option value={5}>5</option>
                                <option value={8}>8</option>
                                <option value={10}>10</option>
                                <option value={15}>15</option>
                                <option value={25}>25</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            <DeleteConfirmModal
                isOpen={!!deleteTarget}
                onClose={() => setDeleteTarget(null)}
                namaKantin={deleteTarget?.nama_kantin ?? ''}
                logoPath={deleteTarget?.logo_path}
                isDeleting={isDeleting}
                onConfirm={() => {
                    setIsDeleting(true);
                    router.delete(route('admin.canteens.destroy', deleteTarget.id), {
                        onFinish: () => {
                            setIsDeleting(false);
                            setDeleteTarget(null);
                        },
                    });
                }}
            />
        </AdminLayout>
    );
}
