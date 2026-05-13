import React from 'react';

export default function StatusBadge({ status, type = 'dot' }) {
    let styleClasses = '';
    let hasDot = false;
    let dotColor = '';

    // Menyesuaikan warna berdasarkan teks status
    switch (status?.toLowerCase()) {
        case 'aktif':
        case 'berhasil':
            styleClasses = 'bg-green-50 text-green-700 border-green-100';
            hasDot = type === 'dot' && status?.toLowerCase() === 'aktif';
            dotColor = 'bg-green-500';
            break;
        case 'nonaktif':
        case 'gagal':
            styleClasses = 'bg-red-50 text-red-700 border-red-100';
            hasDot = type === 'dot' && status?.toLowerCase() === 'nonaktif';
            dotColor = 'bg-red-500';
            break;
        case 'pending':
            styleClasses = 'bg-yellow-50 text-yellow-700 border-yellow-100';
            break;
        default:
            styleClasses = 'bg-gray-50 text-gray-700 border-gray-100';
    }

    return (
        <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border ${styleClasses}`}>
            {hasDot && (
                <span className={`w-1.5 h-1.5 rounded-full ${dotColor}`}></span>
            )}
            {status}
        </span>
    );
}