import React, { useEffect } from 'react';
import { useForm } from '@inertiajs/react';
import Modal from '@/Components/Modal';

export default function ApprovalModal({ isOpen, onClose, application }) {
    const { data, setData, post, processing, reset } = useForm({
        account_expires_at: '',
    });

    useEffect(() => {
        if (isOpen) {
            setData('account_expires_at', application?.account_expires_at ? application.account_expires_at.split('T')[0] : '');
        }
    }, [isOpen, application]);

    const handleApprove = (event) => {
        event.preventDefault();

        // Request diarahkan ke controller; transaksi pembuatan akun ditangani oleh ApprovalService.
        post(`/admin/approvals/${application.id}/approve`, {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                onClose();
            },
        });
    };

    return (
        <Modal show={isOpen} onClose={onClose} maxWidth="lg" closeable={!processing}>
            <form onSubmit={handleApprove}>
                <div className="p-6">
                    <div className="flex items-start gap-4">
                        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-emerald-50 text-emerald-600">
                            <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
                            </svg>
                        </div>

                        <div className="min-w-0 flex-1">
                            <h2 className="text-lg font-bold text-gray-900">Setujui Akun Mahasiswa</h2>
                            <p className="mt-2 text-sm leading-6 text-gray-600">
                                Akun untuk <span className="font-semibold text-gray-900">{application?.name}</span> akan dibuat sebagai pembeli mahasiswa.
                            </p>

                            <div className="mt-4 rounded-xl border border-gray-100 bg-gray-50 p-4">
                                <dl className="grid gap-3 text-sm sm:grid-cols-2">
                                    <div>
                                        <dt className="text-xs font-semibold uppercase tracking-wide text-gray-400">NIM</dt>
                                        <dd className="mt-1 font-semibold text-gray-900">{application?.nim || '-'}</dd>
                                    </div>
                                    <div>
                                        <dt className="text-xs font-semibold uppercase tracking-wide text-gray-400">Email</dt>
                                        <dd className="mt-1 break-words font-semibold text-gray-900">{application?.email || '-'}</dd>
                                    </div>
                                </dl>
                                
                                <div className="mt-4 border-t border-gray-200 pt-4">
                                    <label className="block text-xs font-semibold uppercase tracking-wide text-gray-400">
                                        Masa Berlaku Akun
                                    </label>
                                    <input
                                        type="date"
                                        value={data.account_expires_at}
                                        onChange={(e) => setData('account_expires_at', e.target.value)}
                                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-emerald-500 focus:ring-emerald-500 sm:text-sm"
                                    />
                                    <p className="mt-1 text-xs text-gray-500">Tanggal akun akan kadaluarsa. Kosongkan untuk masa berlaku permanen atau ikuti default.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex flex-col-reverse gap-3 border-t border-gray-100 bg-gray-50 px-6 py-4 sm:flex-row sm:justify-end">
                    <button
                        type="button"
                        onClick={onClose}
                        disabled={processing}
                        className="inline-flex justify-center rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-bold text-gray-700 transition hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        Batal
                    </button>
                    <button
                        type="submit"
                        disabled={processing || !application?.id}
                        className="inline-flex justify-center rounded-lg border border-green-200 bg-green-50 px-4 py-2.5 text-sm font-bold text-green-600 shadow-sm transition hover:bg-green-100 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {processing ? 'Memproses...' : 'Setujui Pengajuan'}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
