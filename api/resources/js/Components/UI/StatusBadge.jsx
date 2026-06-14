import React from 'react';

export default function StatusBadge({ status, type = 'dot' }) {
    let styleClasses = '';
    let hasDot = false;
    let dotColor = '';

    // Menyesuaikan warna berdasarkan teks status
    const lowerStatus = status?.toLowerCase();
    let displayStatus = status;

    switch (lowerStatus) {
        case 'aktif':
        case 'berhasil':
        case 'approved':
        case 'disetujui':
            styleClasses = 'bg-green-50 text-green-700 border-green-100';
            hasDot = type === 'dot';
            dotColor = 'bg-green-500';
            displayStatus = lowerStatus === 'approved' ? 'Disetujui' : displayStatus;
            break;
        case 'nonaktif':
        case 'gagal':
        case 'rejected':
        case 'ditolak':
            styleClasses = 'bg-red-50 text-red-700 border-red-100';
            hasDot = type === 'dot';
            dotColor = 'bg-red-500';
            displayStatus = lowerStatus === 'rejected' ? 'Ditolak' : displayStatus;
            break;
        case 'pending':
            styleClasses = 'bg-yellow-50 text-yellow-700 border-yellow-100';
            hasDot = type === 'dot';
            dotColor = 'bg-yellow-500';
            displayStatus = 'Pending';
            break;
        default:
            styleClasses = 'bg-gray-50 text-gray-700 border-gray-100';
    }

    return (
        <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${styleClasses}`}>
            {hasDot && (
                <span className={`w-1.5 h-1.5 rounded-full ${dotColor}`}></span>
            )}
            {displayStatus}
        </span>
    );
}