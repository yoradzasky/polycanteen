import React from 'react';
import { useForm } from '@inertiajs/react';

export default function RejectionModal({ isOpen, onClose, application }) {
    const { data, setData, post, processing, errors, reset } = useForm({
        reason: '',
    });

    if (!isOpen || !application) return null;

    const handleReject = (e) => {
        e.preventDefault();
        post(`/admin/approvals/${application.id}/reject`, {
            preserveScroll: true,
            onSuccess: () => {
                reset(); // reset form alasan
                onClose(); // tutup modal
            },
        });
    };

    const handleClose = () => {
        reset();
        onClose();
    };

    return (
        <div className="fixed inset-0 z-50 overflow-y-auto">
            <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
                {/* Overlay Background */}
                <div 
                    className="fixed inset-0 transition-opacity bg-gray-900 bg-opacity-50 backdrop-blur-sm" 
                    aria-hidden="true" 
                    onClick={handleClose}
                ></div>

                {/* Modal Panel */}
                <div className="inline-block overflow-hidden text-left align-bottom transition-all transform bg-white rounded-lg shadow-2xl sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                    <form onSubmit={handleReject}>
                        <div className="px-4 pt-5 pb-4 bg-white sm:p-6 sm:pb-4">
                            <div className="sm:flex sm:items-start">
                                <div className="flex items-center justify-center flex-shrink-0 w-12 h-12 mx-auto bg-red-100 rounded-full sm:mx-0 sm:h-10 sm:w-10">
                                    {/* Cross Icon */}
                                    <svg className="w-6 h-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                                    </svg>
                                </div>
                                <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                                    <h3 className="text-xl font-semibold leading-6 text-gray-900">Reject Application</h3>
                                    <div className="mt-3">
                                        <p className="text-sm text-gray-500 mb-4">
                                            Are you sure you want to reject the application for <strong>{application.name}</strong>? 
                                            Please provide a reason below. This will be recorded in the system.
                                        </p>
                                        <textarea
                                            value={data.reason}
                                            onChange={(e) => setData('reason', e.target.value)}
                                            className={`w-full px-3 py-2 border rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm ${errors.reason ? 'border-red-300' : 'border-gray-300'}`}
                                            rows="3"
                                            placeholder="Reason for rejection (e.g., Invalid Student ID format, Documentation mismatch)"
                                            required
                                        ></textarea>
                                        {errors.reason && <p className="mt-1 text-sm text-red-600 font-medium">{errors.reason}</p>}
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="px-4 py-3 bg-gray-50 sm:px-6 sm:flex sm:flex-row-reverse border-t border-gray-100">
                            <button
                                type="submit"
                                disabled={processing}
                                className={`inline-flex justify-center w-full px-4 py-2 text-base font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm ${processing ? 'opacity-70 cursor-not-allowed' : ''}`}
                            >
                                {processing ? 'Rejecting...' : 'Confirm Rejection'}
                            </button>
                            <button
                                type="button"
                                onClick={handleClose}
                                disabled={processing}
                                className="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                            >
                                Cancel
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
