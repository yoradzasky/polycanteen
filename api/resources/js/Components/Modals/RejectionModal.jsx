import React from 'react';
import { useForm } from '@inertiajs/react';
import Modal from '@/Components/Modal';

export default function RejectionModal({ isOpen, onClose, application }) {
    const { data, setData, post, processing, errors, reset } = useForm({
        reason: '',
    });

    const closeModal = () => {
        reset();
        onClose();
    };

    const handleReject = (event) => {
        event.preventDefault();

        // Alasan penolakan disimpan pada buyer_applications.rejection_reason.
        post(`/admin/approvals/${application.id}/reject`, {
            preserveScroll: true,
            onSuccess: closeModal,
        });
    };

    return (
        <Modal show={isOpen} onClose={closeModal} maxWidth="lg" closeable={!processing}>
            <form onSubmit={handleReject}>
                <div className="p-6">
                    <div className="flex items-start gap-4">
                        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-red-50 text-red-600">
                            <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
                            </svg>
                        </div>

                        <div className="min-w-0 flex-1">
                            <h2 className="text-lg font-bold text-gray-900">Tolak Pengajuan Akun</h2>
                            <p className="mt-2 text-sm leading-6 text-gray-600">
                                Pengajuan <span className="font-semibold text-gray-900">{application?.name}</span> akan ditandai sebagai ditolak.
                            </p>

                            <label htmlFor="rejection-reason" className="mt-5 block text-sm font-semibold text-gray-800">
                                Alasan Penolakan
                            </label>
                            <textarea
                                id="rejection-reason"
                                value={data.reason}
                                onChange={(event) => setData('reason', event.target.value)}
                                rows="4"
                                required
                                maxLength="500"
                                placeholder="Contoh: Foto KTM tidak terbaca atau NIM tidak sesuai."
                                className={`mt-2 w-full resize-none rounded-lg border px-3 py-2 text-sm text-gray-800 shadow-sm focus:border-[#3949AB] focus:ring-[#3949AB] ${errors.reason ? 'border-red-300' : 'border-gray-300'}`}
                            />
                            <div className="mt-1 flex justify-between gap-3 text-xs">
                                <p className="font-medium text-red-600">{errors.reason}</p>
                                <p className="text-gray-400">{data.reason.length}/500</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex flex-col-reverse gap-3 border-t border-gray-100 bg-gray-50 px-6 py-4 sm:flex-row sm:justify-end">
                    <button
                        type="button"
                        onClick={closeModal}
                        disabled={processing}
                        className="inline-flex justify-center rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-bold text-gray-700 transition hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        Batal
                    </button>
                    <button
                        type="submit"
                        disabled={processing || !application?.id}
                        className="inline-flex justify-center rounded-lg border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-bold text-red-600 shadow-sm transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {processing ? 'Memproses...' : 'Tolak Pengajuan'}
                    </button>
                </div>
            </form>
        </Modal>
    );
}
