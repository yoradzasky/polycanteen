import React, { useState, useEffect } from "react";
import { Head, Link, router } from "@inertiajs/react";
import StatusBadge from "@/Components/UI/StatusBadge";
import DeactivateConfirmModal from "@/Components/Modals/DeactivateConfirmModal";
import AdminLayout from "@/Layouts/AdminLayout";

export default function Index({ buyers, filters }) {
    // Menggunakan data asli dari database (buyers), bukan dummyData lagi
    const dataToRender = buyers?.data || [];

    // 1. Ambil nilai default search dari URL (filters.search) agar tidak hilang saat refresh
    const [search, setSearch] = useState(filters?.search || "");
    const [selectedUserForDeactivation, setSelectedUserForDeactivation] = useState(null);
    const [isProcessingDeactivate, setIsProcessingDeactivate] = useState(false);



    // 2. Tambahkan useEffect untuk auto-search (debounce)
    useEffect(() => {
        // Mencegah request berulang saat halaman baru pertama kali dimuat
        if (search === (filters?.search || "")) return;

        // Tunggu 400ms setelah user berhenti mengetik, baru tembak ke backend
        const delaySearch = setTimeout(() => {
            router.get(
                "/admin/buyers",
                { search: search },
                {
                    preserveState: true,
                    replace: true,
                },
            );
        }, 400);

        // Bersihkan timer jika user mengetik lagi sebelum 400ms
        return () => clearTimeout(delaySearch);
    }, [search, filters?.search]);



    // Komponen Search Bar (Ukuran & Gaya 100% sama dengan TopNavbar)
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
            title="Daftar Mahasiswa"
            description="Kelola seluruh akun mahasiswa"
            rightContent={renderSearchBar}
        >
            <Head title="Daftar Mahasiswa" />

            <div className="p-6 lg:p-8 font-sans pb-20 w-full">
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                    <div className="p-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 border-b border-gray-100">
                        <div>
                            <h2 className="text-lg font-semibold text-gray-900">
                                Daftar Akun Mahasiswa
                            </h2>
                            <p className="text-sm text-gray-500 mt-1">
                                Total {buyers?.total || 0} mahasiswa —
                                menampilkan {buyers?.from || 0}-
                                {buyers?.to || 0}
                            </p>
                        </div>

                        <div className="flex items-center gap-3">
                            {/* Filter and Export buttons removed */}
                        </div>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-sm text-left text-gray-600">
                            <thead className="text-xs text-gray-400 uppercase bg-white border-b-2 border-gray-200">
                                <tr>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        Nama & NIM
                                    </th>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        Email
                                    </th>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        No HP
                                    </th>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        Total Transaksi
                                    </th>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        Status
                                    </th>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        Tanggal Daftar
                                    </th>
                                    <th
                                        scope="col"
                                        className="px-6 py-4 font-semibold tracking-wider"
                                    >
                                        Aksi
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                {dataToRender.length > 0 ? (
                                    dataToRender.map((user, index) => (
                                        <tr
                                            key={index}
                                            className="bg-white border-b-2 border-gray-200 hover:bg-gray-50/50 transition-colors"
                                        >
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="flex items-center gap-3">
                                                    {/* --- PERBAIKAN: Lingkaran Profil --- */}
                                                    {user.foto_profil_path ? (
                                                        <img
                                                            src={
                                                                user.foto_profil_path.startsWith(
                                                                    "http",
                                                                )
                                                                    ? user.foto_profil_path
                                                                    : `/storage/${user.foto_profil_path}`
                                                            }
                                                            alt={user.name}
                                                            className="w-10 h-10 rounded-full object-cover border border-gray-200 shrink-0"
                                                        />
                                                    ) : (
                                                        <div className="w-10 h-10 rounded-full shrink-0 bg-[#3949AB] text-white flex items-center justify-center font-bold border border-gray-200">
                                                            {user.name
                                                                ? user.name
                                                                      .split(
                                                                          " ",
                                                                      )
                                                                      .map(
                                                                          (n) =>
                                                                              n[0],
                                                                      )
                                                                      .join("")
                                                                      .substring(
                                                                          0,
                                                                          2,
                                                                      )
                                                                      .toUpperCase()
                                                                : "U"}
                                                        </div>
                                                    )}
                                                    {/* ---------------------------------- */}

                                                    <div>
                                                        <div className="font-semibold text-gray-900">
                                                            {user.name}
                                                        </div>
                                                        <div className="text-xs text-gray-500">
                                                            {user.nim || "-"}
                                                        </div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                {user.email}
                                            </td>
                                            <td className="px-6 py-4">
                                                {user.phone}
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="font-semibold text-gray-900">
                                                    {user.total_rp}
                                                </div>
                                                <div className="text-xs text-gray-400">
                                                    {user.total_trx}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <StatusBadge
                                                    status={user.status}
                                                    type="dot"
                                                />
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="text-gray-900">
                                                    {user.date}
                                                </div>
                                                <div className="text-xs text-gray-400">
                                                    {user.time}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-2">
                                                    {/* TOMBOL DETAIL */}
                                                    <Link
                                                        href={`/admin/buyers/${user.id}`}
                                                        className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                                                    >
                                                        <svg
                                                            className="w-3.5 h-3.5"
                                                            fill="none"
                                                            viewBox="0 0 24 24"
                                                            stroke="currentColor"
                                                            strokeWidth={2}
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

                                                    {/* TOMBOL HAPUS - Sekarang identik dengan tombol Detail */}
                                                    <button
                                                        className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                                                        onClick={() => setSelectedUserForDeactivation(user)}
                                                    >
                                                        <svg
                                                            className="w-3.5 h-3.5"
                                                            fill="none"
                                                            viewBox="0 0 24 24"
                                                            stroke="currentColor"
                                                            strokeWidth={2}
                                                        >
                                                            <path
                                                                strokeLinecap="round"
                                                                strokeLinejoin="round"
                                                                d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
                                                            />
                                                        </svg>
                                                        Hapus
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td
                                            colSpan="7"
                                            className="px-6 py-16 text-center"
                                        >
                                            <div className="flex flex-col items-center justify-center w-full">
                                                <svg
                                                    className="w-12 h-12 text-gray-300 mb-3"
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
                                                <p className="text-gray-500">
                                                    Tidak ada data mahasiswa
                                                    yang ditemukan.
                                                </p>
                                            </div>
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>

                    {/* Pagination Laravel */}
                    {buyers?.links && buyers.links.length > 3 && (
                        <div className="p-6 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4">
                            <span className="text-sm text-gray-500">
                                Showing{" "}
                                <span className="font-medium text-gray-900">
                                    {buyers.from || 0}–{buyers.to || 0}
                                </span>{" "}
                                of{" "}
                                <span className="font-medium text-gray-900">
                                    {buyers.total || 0}
                                </span>{" "}
                                mahasiswa
                            </span>
                            <div className="flex items-center gap-1">
                                {buyers.links.map((link, key) => {
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
                                            className={`w-8 h-8 flex items-center justify-center rounded text-sm font-medium ${link.active ? "bg-[#3949AB] text-white" : link.url ? "hover:bg-gray-50 text-gray-600" : "text-gray-400"}`}
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

            {/* Modal Nonaktifkan Akun */}
            <DeactivateConfirmModal
                isOpen={!!selectedUserForDeactivation}
                onClose={() => setSelectedUserForDeactivation(null)}
                onConfirm={() => {
                    if (!selectedUserForDeactivation) return;
                    router.delete(`/admin/buyers/${selectedUserForDeactivation.id}`, {
                        preserveScroll: true,
                        onStart: () => setIsProcessingDeactivate(true),
                        onFinish: () => {
                            setIsProcessingDeactivate(false);
                            setSelectedUserForDeactivation(null);
                        }
                    });
                }}
                namaPengguna={selectedUserForDeactivation?.name}
                avatarPath={selectedUserForDeactivation?.foto_profil_path?.startsWith("http") ? selectedUserForDeactivation.foto_profil_path : selectedUserForDeactivation?.foto_profil_path ? `/storage/${selectedUserForDeactivation.foto_profil_path}` : null}
                isProcessing={isProcessingDeactivate}
            />
        </AdminLayout>
    );
}
