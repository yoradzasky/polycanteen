import React from 'react';
import { Head, Link } from '@inertiajs/react';

export default function Show({ application }) {
    // Fallback mockup data jika API/database belum terintegrasi penuh
    const data = application || {
        id: 1,
        name: 'Budi Santoso',
        email: 'budi@student.poly.edu',
        nim: '12345678',
        major: 'Informatics Engineering',
        created_at: '2026-05-18T10:00:00Z',
        status: 'pending'
    };

    return (
        <div className="py-12">
            <Head title={`Application: ${data.name}`} />
            <div className="max-w-4xl mx-auto sm:px-6 lg:px-8">
                <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                    <div className="p-8 bg-white border-b border-gray-200">
                        <div className="flex justify-between items-center mb-6 border-b pb-4">
                            <h2 className="text-2xl font-bold text-gray-800">Application Details</h2>
                            <Link href="/admin/approvals" className="text-indigo-600 hover:text-indigo-800 hover:underline flex items-center gap-1">
                                <span>&larr;</span> Back to List
                            </Link>
                        </div>
                        
                        <div className="bg-gray-50 rounded-xl p-8 shadow-inner border border-gray-100">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-8">
                                <div>
                                    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Full Name</h3>
                                    <p className="mt-2 text-lg text-gray-900 font-medium">{data.name}</p>
                                </div>
                                <div>
                                    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Student ID (NIM)</h3>
                                    <p className="mt-2 text-lg text-gray-900">{data.nim}</p>
                                </div>
                                <div>
                                    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Email Address</h3>
                                    <p className="mt-2 text-lg text-gray-900">{data.email}</p>
                                </div>
                                <div>
                                    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Major / Program</h3>
                                    <p className="mt-2 text-lg text-gray-900">{data.major || 'Not Provided'}</p>
                                </div>
                                <div>
                                    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Registration Date</h3>
                                    <p className="mt-2 text-lg text-gray-900">{new Date(data.created_at).toLocaleString()}</p>
                                </div>
                                <div>
                                    <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Status</h3>
                                    <div className="mt-2">
                                        <span className="px-3 py-1 inline-flex text-sm leading-5 font-bold rounded-full bg-yellow-100 text-yellow-800 uppercase">
                                            {data.status}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
