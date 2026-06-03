import React from 'react';

const STATUS_STYLES = {
    pending: {
        label: 'Pending',
        classes: 'border-amber-200 bg-amber-50 text-amber-700',
        dot: 'bg-amber-500',
    },
    aktif: {
        label: 'Aktif',
        classes: 'border-emerald-200 bg-emerald-50 text-emerald-700',
        dot: 'bg-emerald-500',
    },
    ditolak: {
        label: 'Ditolak',
        classes: 'border-red-200 bg-red-50 text-red-700',
        dot: 'bg-red-500',
    },
};

export default function StatusBadge({ status }) {
    const normalizedStatus = String(status || '').toLowerCase();
    const config = STATUS_STYLES[normalizedStatus] || {
        label: status || 'Tidak diketahui',
        classes: 'border-gray-200 bg-gray-50 text-gray-600',
        dot: 'bg-gray-400',
    };

    return (
        <span className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium ${config.classes}`}>
            <span className={`h-1.5 w-1.5 rounded-full ${config.dot}`} />
            {config.label}
        </span>
    );
}
