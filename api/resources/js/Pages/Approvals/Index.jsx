import React, { useState, useEffect } from "react";
import { Head, Link, router } from "@inertiajs/react";
import StatusBadge from "@/Components/UI/StatusBadge";
import AdminLayout from "@/Layouts/AdminLayout";

export default function Index({ applications, filters }) {
    const dataToRender = applications?.data || [];
    const [search, setSearch] = useState(filters?.search || "");

    useEffect(() => {
        if (search === (filters?.search || "")) return;

        const delaySearch = setTimeout(() => {
            router.get(
                route('admin.approvals.index'),
                { search: search },
                {
                    preserveState: true,
                    replace: true,
                },
            );
        }, 400);

        return () => clearTimeout(delaySearch);
    }, [search, filters?.search]);

    const renderSearchBar = (
        <form 
            role="search" 
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-[#f4f6fb] rounded-xl border border-gray-100" 
            onSubmit={(e) => e.preventDefault()}
        >
            <svg 
                className="w-3.5 h-3.5 text-gray-400 shrink-0" 
                viewBox="0 0 14 14" 
                fill="none" 
                xmlns="http://www.w3.org/2000/svg"
            >
                <path 
                    d="M12.25 12.25L9.7125 9.7125M11.0833 6.41667C11.0833 8.994 8.994 11.0833 6.41667 11.0833C3.83934 11.0833 1.75 8.994 1.75 6.41667C1.75 3.83934 3.83934 1.75 6.41667 1.75C8.994 1.75 11.0833 3.83934 11.0833 6.41667Z" 
                    stroke="currentColor" 
                    strokeWidth="1.4" 
                    strokeLinecap="round" 
                    strokeLinejoin="round" 
                />
            </svg>
            <input
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Cari nama atau nim..."
                className="bg-transparent outline-none border-0 p-0 text-sm placeholder:text-gray-400 w-40 focus:ring-0"
            />
        </form>
    );

    return (
        <AdminLayout
            title="Persetujuan Akun"
            description="Tinjau pendaftaran mahasiswa yang menunggu persetujuan"
            rightContent={renderSearchBar}
        >
            <Head title="Persetujuan Akun" />

            <div className="p-6 lg:p-8 font-sans pb-20 w-full">
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                    <div className="p-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 border-b border-gray-100">
                        <div>
                            <h2 className="text-lg font-semibold text-gray-900">
                                Permintaan Akun Pending
                            </h2>
                            <p className="text-sm text-gray-500 mt-1">
                                Total {applications?.total || 0} permintaan perlu ditinjau — menampilkan{" "}
                                {applications?.from || 0}-{applications?.to || 0}
                            </p>
                        </div>

                        <div className="flex items-center gap-3">
                            <button className="inline-flex items-center gap-2 px-4 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-100 shadow-sm transition-colors">
                                <svg
                                    className="w-4 h-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                        strokeWidth="2"
                                        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                                    />
                                </svg>
                                Export
                            </button>
                        </div>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-sm text-left text-gray-600">
                            <thead className="text-xs text-gray-400 uppercase bg-white border-b-2 border-gray-200">
                                <tr>
                                    <th scope="col" className="px-6 py-4 font-semibold tracking-wider">
                                        Mahasiswa
                                    </th>
                                    <th scope="col" className="px-6 py-4 font-semibold tracking-wider">
                                        Email
                                    </th>
                                    <th scope="col" className="px-6 py-4 font-semibold tracking-wider">
                                        Tanggal Daftar
                                    </th>
                                    <th scope="col" className="px-6 py-4 font-semibold tracking-wider">
                                        Status
                                    </th>
                                    <th scope="col" className="px-6 py-4 font-semibold tracking-wider text-center">
                                        Aksi
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                {dataToRender.length > 0 ? (
                                    dataToRender.map((app, index) => (
                                        <tr
                                            key={index}
                                            className="bg-white border-b-2 border-gray-200 hover:bg-gray-50/50 transition-colors"
                                        >
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-10 h-10 rounded-full bg-[#3949AB] text-white flex items-center justify-center font-bold">
                                                        {app.name
                                                            ? app.name
                                                                  .split(" ")
                                                                  .map((n) => n[0])
                                                                  .join("")
                                                                  .substring(0, 2)
                                                                  .toUpperCase()
                                                            : "U"}
                                                    </div>
                                                    <div>
                                                        <div className="font-semibold text-gray-900">
                                                            {app.name}
                                                        </div>
                                                        <div className="text-xs text-gray-500">
                                                            {app.nim || "-"}
                                                        </div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                {app.email}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-gray-900">
                                                    {new Date(app.created_at).toLocaleDateString('id-ID', {
                                                        day: '2-digit',
                                                        month: 'long',
                                                        year: 'numeric'
                                                    })}
                                                </div>
                                                <div className="text-xs text-gray-400">
                                                    {new Date(app.created_at).toLocaleTimeString('id-ID', {
                                                        hour: '2-digit',
                                                        minute: '2-digit'
                                                    })} WIB
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <StatusBadge
                                                    status={app.status}
                                                    type="dot"
                                                />
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-center">
                                                <Link
                                                    href={route('admin.approvals.show', app.id)}
                                                    className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors border border-blue-100 shadow-sm"
                                                >
                                                    <svg
                                                        className="w-3.5 h-3.5"
                                                        fill="none"
                                                        viewBox="0 0 24 24"
                                                        stroke="currentColor"
                                                        strokeWidth={2.5}
                                                    >
                                                        <path
                                                            strokeLinecap="round"
                                                            strokeLinejoin="round"
                                                            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                                                        />
                                                        <path
                                                            strokeLinecap="round"
                                                            strokeLinejoin="round"
                                                            d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                                                        />
                                                    </svg>
                                                    Detail
                                                </Link>
                                            </td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td
                                            colSpan="5"
                                            className="px-6 py-16 text-center"
                                        >
                                            <div className="flex flex-col items-center justify-center w-full">
                                                <svg
                                                    className="w-12 h-12 text-gray-200 mb-3"
                                                    fill="none"
                                                    stroke="currentColor"
                                                    viewBox="0 0 24 24"
                                                >
                                                    <path
                                                        strokeLinecap="round"
                                                        strokeLinejoin="round"
                                                        strokeWidth="2"
                                                        d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                                                    />
                                                </svg>
                                                <p className="text-gray-400 text-sm">
                                                    Tidak ada data permintaan yang ditemukan.
                                                </p>
                                            </div>
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>

                    {/* Pagination Laravel */}
                    {applications?.links && applications.links.length > 3 && (
                        <div className="p-6 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4">
                            <span className="text-sm text-gray-500">
                                Showing{" "}
                                <span className="font-medium text-gray-900">
                                    {applications.from || 0}–{applications.to || 0}
                                </span>{" "}
                                of{" "}
                                <span className="font-medium text-gray-900">
                                    {applications.total || 0}
                                </span>{" "}
                                permintaan
                            </span>
                            <div className="flex items-center gap-1">
                                {applications.links.map((link, key) => {
                                    let label = link.label
                                        .replace("&laquo;", "")
                                        .replace("&raquo;", "")
                                        .trim();
                                    if (link.label.includes("Previous")) {
                                        return (
                                            <Link
                                                key={key}
                                                href={link.url || "#"}
                                                className={`w-8 h-8 flex items-center justify-center rounded ${link.url ? "bg-gray-50 text-gray-600 hover:bg-gray-100" : "bg-gray-50 text-gray-300 pointer-events-none"}`}
                                            >
                                                <svg
                                                    className="w-4 h-4"
                                                    fill="none"
                                                    stroke="currentColor"
                                                    viewBox="0 0 24 24"
                                                >
                                                    <path
                                                        strokeLinecap="round"
                                                        strokeLinejoin="round"
                                                        strokeWidth="2"
                                                        d="M15 19l-7-7 7-7"
                                                    />
                                                </svg>
                                            </Link>
                                        );
                                    }
                                    if (link.label.includes("Next")) {
                                        return (
                                            <Link
                                                key={key}
                                                href={link.url || "#"}
                                                className={`w-8 h-8 flex items-center justify-center rounded ${link.url ? "bg-gray-50 text-gray-600 hover:bg-gray-100" : "bg-gray-50 text-gray-300 pointer-events-none"}`}
                                            >
                                                <svg
                                                    className="w-4 h-4"
                                                    fill="none"
                                                    stroke="currentColor"
                                                    viewBox="0 0 24 24"
                                                >
                                                    <path
                                                        strokeLinecap="round"
                                                        strokeLinejoin="round"
                                                        strokeWidth="2"
                                                        d="M9 5l7 7-7 7"
                                                    />
                                                </svg>
                                            </Link>
                                        );
                                    }
                                    return (
                                        <Link
                                            key={key}
                                            href={link.url || "#"}
                                            className={`w-8 h-8 flex items-center justify-center rounded text-sm font-medium ${link.active ? "bg-[#3949AB] text-white shadow-sm" : link.url ? "hover:bg-gray-50 text-gray-600" : "text-gray-400"}`}
                                        >
                                            {label}
                                        </Link>
                                    );
                                })}
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </AdminLayout>
    );
}
