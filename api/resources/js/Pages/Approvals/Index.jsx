import React, { useState } from 'react';
import { Head, Link } from '@inertiajs/react';
import ApprovalModal from '@/Components/Modals/ApprovalModal';
import RejectionModal from '@/Components/Modals/RejectionModal';

export default function Index({ applications }) {
    // Memberikan mockup data fallback jika `applications` dari server belum berisi/kosong
    const data = applications?.data || [
        { id: 1, name: 'Budi Santoso', email: 'budi@student.poly.edu', nim: '12345678', created_at: '2026-05-18T10:00:00Z', status: 'pending' },
        { id: 2, name: 'Siti Aminah', email: 'siti@student.poly.edu', nim: '87654321', created_at: '2026-05-17T14:30:00Z', status: 'pending' },
    ];

    const [selectedApp, setSelectedApp] = useState(null);
    const [isApprovalModalOpen, setApprovalModalOpen] = useState(false);
    const [isRejectionModalOpen, setRejectionModalOpen] = useState(false);

    const openApprove = (app) => {
        setSelectedApp(app);
        setApprovalModalOpen(true);
    };

    const openReject = (app) => {
        setSelectedApp(app);
        setRejectionModalOpen(true);
    };

    return (
        <div className="py-12">
            <Head title="Pending Approvals" />
            <div className="max-w-7xl mx-auto sm:px-6 lg:px-8">
                <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                    <div className="p-6 bg-white border-b border-gray-200">
                        <h2 className="text-2xl font-bold mb-6 text-gray-800">Pending Student Approvals</h2>
                        
                        <div className="overflow-x-auto rounded-lg border border-gray-200">
                            <table className="min-w-full divide-y divide-gray-200">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">NIM</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                                    </tr>
                                </thead>
                                <tbody className="bg-white divide-y divide-gray-200">
                                    {data.map((app) => (
                                        <tr key={app.id} className="hover:bg-gray-50 transition duration-150">
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm font-medium text-gray-900">{app.name}</div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-500">{app.nim}</div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-500">{app.email}</div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm text-gray-500">
                                                    {new Date(app.created_at).toLocaleDateString()}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-3">
                                                <Link href={`/admin/approvals/${app.id}`} className="text-indigo-600 hover:text-indigo-900">
                                                    View
                                                </Link>
                                                <button onClick={() => openApprove(app)} className="text-green-600 hover:text-green-900 transition-colors">
                                                    Approve
                                                </button>
                                                <button onClick={() => openReject(app)} className="text-red-600 hover:text-red-900 transition-colors">
                                                    Reject
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                    {data.length === 0 && (
                                        <tr>
                                            <td colSpan="5" className="px-6 py-8 text-center text-sm text-gray-500">
                                                No pending applications found.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            {/* Modals dipisahkan dari loop row tabel untuk perfoma */}
            <ApprovalModal 
                isOpen={isApprovalModalOpen} 
                onClose={() => setApprovalModalOpen(false)} 
                application={selectedApp} 
            />
            
            <RejectionModal 
                isOpen={isRejectionModalOpen} 
                onClose={() => setRejectionModalOpen(false)} 
                application={selectedApp} 
            />
        </div>
    );
}
