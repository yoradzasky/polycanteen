import React from 'react';
import { Head, Link, usePage } from '@inertiajs/react';

// MENGAPA: Memecah komponen UI kecil (Sub-komponen) di file yang sama
// untuk reusability (StatusBadge, AlertMessage, dll), menjaga struktur file React bersih. (Aturan 14)
const StatusBadge = ({ status }) => {
    const isBuka = status?.toLowerCase() === 'buka';
    
    // MENGAPA: Menggunakan Tailwind class yang lebih matang (ring-1, shadow-sm) 
    // agar terlihat lebih profesional dibanding sekedar background warna solid. (Aturan 15)
    return (
        <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full shadow-sm ring-1 ring-inset ${
            isBuka 
                ? 'bg-green-50 text-green-700 ring-green-600/20' 
                : 'bg-red-50 text-red-700 ring-red-600/20'
        }`}>
            {status?.toUpperCase() || 'TUTUP'}
        </span>
    );
};

const AlertMessage = ({ message, type }) => {
    if (!message) return null;
    
    // MENGAPA: Menampilkan pesan notifikasi langsung di dalam UI
    // sesuai standar UX web app, menghindari native window browser alert(). (Aturan 11)
    const bgClass = type === 'success' 
        ? 'bg-green-50 text-green-800 border-green-200' 
        : 'bg-red-50 text-red-800 border-red-200';
        
    return (
        <div className={`p-4 mb-6 text-sm rounded-xl border shadow-sm ${bgClass}`} role="alert">
            {message}
        </div>
    );
};

const EmptyState = () => (
    // MENGAPA: Empty state mutlak diperlukan agar pengguna tidak kebingungan 
    // saat tabel data masih kosong (zero-data experience yang baik). (Aturan 16)
    <div className="text-center py-20 px-6">
        <div className="mx-auto w-16 h-16 bg-gray-100 flex items-center justify-center rounded-full mb-4 shadow-sm ring-1 ring-gray-200">
            <svg className="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
        </div>
        <h3 className="mt-4 text-base font-semibold text-gray-900">Belum ada kantin yang terdaftar</h3>
        <p className="mt-2 text-sm text-gray-500 max-w-sm mx-auto">Silakan mulai dengan menambahkan data kantin pertama untuk mengelolanya di sistem aplikasi PolyCanteen.</p>
        <div className="mt-8">
            <Link
                href="/admin/canteens/create"
                className="inline-flex items-center justify-center px-5 py-2.5 border border-transparent shadow-sm text-sm font-medium rounded-xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
            >
                + Tambah Kantin Pertama
            </Link>
        </div>
    </div>
);

export default function Index({ canteens }) {
    // MENGAPA: Mengambil properti global 'flash' yang dikirimkan oleh backend Laravel/Inertia (Aturan 11)
    const { flash } = usePage().props;

    return (
        <div className="min-h-screen bg-gray-50 py-10 font-sans">
            <Head title="Manajemen Kantin" />
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                
                {/* Header Section */}
                <div className="sm:flex sm:items-center sm:justify-between mb-8">
                    <div>
                        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Manajemen Kantin</h1>
                        <p className="mt-2 text-sm text-gray-600">Daftar semua kantin beserta status operasionalnya di dalam PolyCanteen.</p>
                    </div>
                    <div className="mt-4 sm:mt-0">
                        <Link
                            href="/admin/canteens/create"
                            className="inline-flex items-center px-5 py-2.5 border border-transparent shadow-sm text-sm font-medium rounded-xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all active:scale-95"
                        >
                            Tambah Kantin Baru
                        </Link>
                    </div>
                </div>

                {/* Flash Messages */}
                <AlertMessage message={flash?.success} type="success" />
                <AlertMessage message={flash?.error} type="error" />

                {/* Table Data Section */}
                <div className="bg-white rounded-2xl shadow-sm ring-1 ring-gray-900/5 overflow-hidden">
                    {canteens && canteens.length > 0 ? (
                        <div className="overflow-x-auto">
                            <table className="min-w-full divide-y divide-gray-200">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th scope="col" className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Nama Kantin</th>
                                        <th scope="col" className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Lokasi Detail</th>
                                        <th scope="col" className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status Buka/Tutup</th>
                                        <th scope="col" className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tanggal Terdaftar</th>
                                    </tr>
                                </thead>
                                <tbody className="bg-white divide-y divide-gray-200">
                                    {canteens.map((kantin) => (
                                        <tr key={kantin.id} className="hover:bg-gray-50/80 transition-colors group">
                                            <td className="px-6 py-5 whitespace-nowrap">
                                                <div className="text-sm font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors">{kantin.nama_kantin}</div>
                                            </td>
                                            <td className="px-6 py-5 whitespace-nowrap">
                                                <div className="text-sm text-gray-500 truncate max-w-xs">{kantin.lokasi_lengkap || 'Belum diatur'}</div>
                                            </td>
                                            <td className="px-6 py-5 whitespace-nowrap">
                                                <StatusBadge status={kantin.status_toko} />
                                            </td>
                                            <td className="px-6 py-5 whitespace-nowrap text-sm text-gray-500">
                                                {new Date(kantin.created_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    ) : (
                        <EmptyState />
                    )}
                </div>
            </div>
        </div>
    );
}
