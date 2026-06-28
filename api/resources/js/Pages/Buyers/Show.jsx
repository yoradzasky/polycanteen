import React, { useState } from "react";
import { Head, Link } from "@inertiajs/react";
import EditExpirationModal from "@/Components/Modals/EditExpirationModal";
import StatusBadge from "@/Components/UI/StatusBadge";
import AdminLayout from "@/Layouts/AdminLayout";

export default function Show({ buyer }) {
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);

    // Menggunakan data 'buyer' kiriman Controller
    const data = buyer || {};

    // 1. Breadcrumb dikembalikan ke posisi rapat (hapus margin kiri tambahan)
    const renderBreadcrumb = (
        <div className="flex items-center gap-2 text-sm font-medium">
            <Link
                href="/admin/buyers"
                className="text-[#3852b4] hover:underline"
            >
                Daftar Mahasiswa
            </Link>
            <span className="text-gray-400">›</span>
            <span className="text-gray-500">Detail</span>
        </div>
    );

    // 2. Tombol Kembali diisolasi di renderBackButton (dengan margin negatif kecil agar lurus)
    const renderBackButton = (
        <Link
            href="/admin/buyers"
            className="text-gray-400 hover:text-[#3852b4] transition-colors p-1 -ml-1"
            title="Kembali"
        >
            <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
            >
                <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2.5"
                    d="M15 19l-7-7 7-7"
                />
            </svg>
        </Link>
    );

    return (
        <AdminLayout
            leftContent={renderBackButton}
            title="Detail Mahasiswa"
            description={renderBreadcrumb}
        >
            <Head title={`Detail Mahasiswa - ${data.name || "Loading..."}`} />

            <div className="p-6 lg:p-8 font-sans pb-20 w-full">
                {data.id ? (
                    <>
                        {/* Card 1: Profil User */}
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6 flex flex-col md:flex-row items-start md:items-center gap-6">
                            <div className="relative shrink-0">
                                {/* --- PERBAIKAN: Foto Profil Show.jsx --- */}
                                {data.avatar ? (
                                    <img
                                        src={
                                            data.avatar.startsWith("http")
                                                ? data.avatar
                                                : `/storage/${data.avatar}`
                                        }
                                        alt={data.name}
                                        className="w-20 h-20 rounded-xl object-cover"
                                    />
                                ) : (
                                    <div className="w-20 h-20 rounded-xl bg-[#3852b4] text-white flex items-center justify-center text-3xl font-bold">
                                        {data.name
                                            ? data.name
                                                  .split(" ")
                                                  .map((n) => n[0])
                                                  .join("")
                                                  .substring(0, 2)
                                                  .toUpperCase()
                                            : "U"}
                                    </div>
                                )}
                                {/* --------------------------------------- */}

                                <span
                                    className={`absolute -bottom-1 -right-1 w-4 h-4 border-2 border-white rounded-full ${data.status === "Aktif" ? "bg-green-500" : "bg-red-500"}`}
                                ></span>
                            </div>

                            <div className="flex-1">
                                <div className="flex items-center gap-3 mb-3">
                                    <h2 className="text-xl font-bold text-gray-900">
                                        {data.name}
                                    </h2>
                                    <StatusBadge
                                        status={data.status}
                                        type="dot"
                                    />
                                </div>

                                <div className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-gray-600">
                                    {/* Email */}
                                    <div className="flex items-center gap-2">
                                        <svg
                                            className="w-4 h-4 text-gray-400"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                strokeLinecap="round"
                                                strokeLinejoin="round"
                                                strokeWidth="2"
                                                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                                            />
                                        </svg>
                                        {data.email}
                                    </div>

                                    {/* --- TAMBAHAN BARU: NIM Mahasiswa --- */}
                                    <div className="flex items-center gap-2">
                                        <svg
                                            className="w-4 h-4 text-gray-400"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                strokeLinecap="round"
                                                strokeLinejoin="round"
                                                strokeWidth="2"
                                                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V8a2 2 0 00-2-2h-4m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h3"
                                            />
                                        </svg>
                                        {data.nim || "NIM Tidak Tersedia"}
                                    </div>
                                    {/* ------------------------------------ */}

                                    {/* No HP */}
                                    <div className="flex items-center gap-2">
                                        <svg
                                            className="w-4 h-4 text-[#3949AB]"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                strokeLinecap="round"
                                                strokeLinejoin="round"
                                                strokeWidth="2"
                                                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                                            />
                                        </svg>
                                        {data.phone}
                                    </div>

                                    {/* Tanggal Bergabung */}
                                    <div className="flex items-center gap-2">
                                        <svg
                                            className="w-4 h-4 text-[#3949AB]"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                strokeLinecap="round"
                                                strokeLinejoin="round"
                                                strokeWidth="2"
                                                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                                            />
                                        </svg>
                                        Bergabung: {data.join_date}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Card 2: Masa Berlaku Akun */}
                        {data.subscription && (
                            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6 flex flex-col xl:flex-row justify-between gap-6">
                                <div className="flex-1 w-full">
                                    <div className="flex flex-wrap items-center gap-3 mb-6">
                                        <div className="w-10 h-10 rounded-full bg-orange-50 flex items-center justify-center text-orange-500">
                                            <svg
                                                className="w-5 h-5"
                                                fill="none"
                                                stroke="currentColor"
                                                viewBox="0 0 24 24"
                                            >
                                                <path
                                                    strokeLinecap="round"
                                                    strokeLinejoin="round"
                                                    strokeWidth="2"
                                                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                                                />
                                            </svg>
                                        </div>
                                        <div>
                                            <h3 className="text-base font-bold text-gray-900">
                                                Masa Berlaku Akun
                                            </h3>
                                            <p className="text-xs text-gray-500">
                                                Periode aktif berlangganan
                                            </p>
                                        </div>

                                        {data.subscription.days_left > 0 ? (
                                            <span className="ml-2 px-3 py-1 bg-orange-50 text-orange-600 text-xs font-semibold rounded-full flex items-center gap-1">
                                                <svg
                                                    className="w-3 h-3"
                                                    viewBox="0 0 20 20"
                                                    fill="currentColor"
                                                >
                                                    <path
                                                        fillRule="evenodd"
                                                        d="M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.68-.398-1.534-.398-2.654A1 1 0 005.05 6.05 6.981 6.981 0 003 11a7 7 0 1011.95-4.95c-.592-.591-.98-.985-1.348-1.467-.363-.476-.724-1.063-1.207-2.03zM12.12 15.12A3 3 0 017 13s.879.5 2.5.5c0-1 .5-4 1.25-4.5.5 1 .786 1.293 1.371 1.879A2.99 2.99 0 0113 13a2.99 2.99 0 01-.879 2.121z"
                                                        clipRule="evenodd"
                                                    />
                                                </svg>
                                                {data.subscription.days_left}{" "}
                                                hari lagi
                                            </span>
                                        ) : (
                                            <span className="ml-2 px-3 py-1 bg-red-50 text-red-600 text-xs font-semibold rounded-full">
                                                Masa aktif telah habis
                                            </span>
                                        )}
                                    </div>

                                    <div className="flex flex-wrap items-center gap-8 mb-6">
                                        <div>
                                            <p className="text-xs text-gray-400 mb-1">
                                                Tanggal Mulai
                                            </p>
                                            <p className="font-semibold text-gray-900">
                                                {data.subscription.start_date}
                                            </p>
                                        </div>
                                        <svg
                                            className="w-5 h-5 text-gray-300"
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                        >
                                            <path
                                                strokeLinecap="round"
                                                strokeLinejoin="round"
                                                strokeWidth="2"
                                                d="M14 5l7 7m0 0l-7 7m7-7H3"
                                            />
                                        </svg>
                                        <div>
                                            <p className="text-xs text-gray-400 mb-1">
                                                Tanggal Berakhir
                                            </p>
                                            <p className="font-semibold text-gray-900">
                                                {data.subscription.end_date}
                                            </p>
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-400 mb-1">
                                                Durasi
                                            </p>
                                            <p className="font-semibold text-gray-900">
                                                {data.subscription.duration}
                                            </p>
                                        </div>
                                    </div>

                                    <div className="w-full">
                                        <div className="flex justify-between text-xs mb-1">
                                            <span className="text-gray-400">
                                                Progres masa aktif
                                            </span>
                                            <span className="text-orange-500 font-medium">
                                                {
                                                    data.subscription
                                                        .progress_percent
                                                }
                                                % telah berlalu
                                            </span>
                                        </div>
                                        <div className="w-full bg-gray-100 rounded-full h-2">
                                            <div
                                                className="bg-[#F59E0B] h-2 rounded-full"
                                                style={{
                                                    width: `${data.subscription.progress_percent}%`,
                                                }}
                                            ></div>
                                        </div>
                                        <div className="flex items-center gap-1.5 mt-2 text-xs text-orange-500">
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
                                                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                                />
                                            </svg>
                                            {data.subscription.days_left <= 5 &&
                                            data.subscription.days_left > 0
                                                ? `Masa aktif akan berakhir dalam ${data.subscription.days_left} hari. Segera perpanjang.`
                                                : data.subscription
                                                        .days_left === 0
                                                  ? "Masa aktif sudah kedaluwarsa. Silakan perpanjang."
                                                  : "Masa aktif masih panjang."}
                                        </div>
                                    </div>
                                </div>

                                <div className="flex flex-col gap-3 min-w-[200px] xl:border-l xl:border-gray-100 xl:pl-6 justify-center">
                                    <button className="w-full inline-flex justify-center items-center gap-2 px-4 py-2.5 bg-[#EF4444] hover:bg-red-600 text-white text-sm font-medium rounded-lg transition-colors shadow-sm">
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
                                                d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
                                            />
                                        </svg>
                                        Hapus Akun
                                    </button>

                                    <button
                                        onClick={() => setIsEditModalOpen(true)}
                                        className="w-full inline-flex justify-center items-center gap-2 px-4 py-2.5 bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 text-sm font-medium rounded-lg transition-colors"
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
                                                d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                                            />
                                        </svg>
                                        Edit Masa Berlaku
                                    </button>
                                </div>
                            </div>
                        )}

                        {/* Card 3: Riwayat Transaksi */}
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                            <div className="p-6 text-center border-b border-gray-50">
                                <h3 className="text-base font-bold text-gray-900">
                                    Riwayat Transaksi
                                </h3>
                                <p className="text-sm text-gray-500 mt-1">
                                    {data.total_transactions || 0} transaksi
                                    tercatat
                                </p>
                            </div>

                            <div className="overflow-x-auto p-4">
                                <table className="w-full text-sm text-left text-gray-600">
                                    <thead className="text-xs text-gray-400 bg-gray-50/50 rounded-lg">
                                        <tr>
                                            <th
                                                scope="col"
                                                className="px-6 py-4 font-semibold tracking-wider rounded-l-lg"
                                            >
                                                Tanggal
                                            </th>
                                            <th
                                                scope="col"
                                                className="px-6 py-4 font-semibold tracking-wider"
                                            >
                                                Kantin
                                            </th>
                                            <th
                                                scope="col"
                                                className="px-6 py-4 font-semibold tracking-wider"
                                            >
                                                Nominal
                                            </th>
                                            <th
                                                scope="col"
                                                className="px-6 py-4 font-semibold tracking-wider rounded-r-lg"
                                            >
                                                Status
                                            </th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {data.transactions &&
                                        data.transactions.length > 0 ? (
                                            data.transactions.map(
                                                (trx, index) => (
                                                    <tr
                                                        key={index}
                                                        className="bg-white border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors"
                                                    >
                                                        <td className="px-6 py-4">
                                                            {trx.date}
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <div className="flex items-center gap-2">
                                                                <div className="w-6 h-6 rounded bg-orange-50 flex items-center justify-center text-orange-500">
                                                                    <svg
                                                                        className="w-3.5 h-3.5"
                                                                        fill="none"
                                                                        stroke="currentColor"
                                                                        viewBox="0 0 24 24"
                                                                    >
                                                                        <path
                                                                            strokeLinecap="round"
                                                                            strokeLinejoin="round"
                                                                            strokeWidth="2"
                                                                            d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                                                                        />
                                                                    </svg>
                                                                </div>
                                                                <span className="font-medium text-gray-900">
                                                                    {trx.kantin}
                                                                </span>
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4 font-semibold text-gray-900">
                                                            {trx.total}
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <StatusBadge
                                                                status={
                                                                    trx.status
                                                                }
                                                                type="solid"
                                                            />
                                                        </td>
                                                    </tr>
                                                ),
                                            )
                                        ) : (
                                            <tr>
                                                <td
                                                    colSpan="4"
                                                    className="px-6 py-8 text-center text-gray-500"
                                                >
                                                    Belum ada riwayat transaksi
                                                    untuk mahasiswa ini.
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Modal Edit Masa Berlaku (Ditampilkan di luar flow dokumen) */}
                        <EditExpirationModal
                            isOpen={isEditModalOpen}
                            onClose={() => setIsEditModalOpen(false)}
                            buyer={data}
                        />
                    </>
                ) : (
                    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-10 text-center flex flex-col items-center justify-center h-64">
                        <svg
                            className="animate-spin h-8 w-8 text-[#3949AB] mb-4"
                            fill="none"
                            viewBox="0 0 24 24"
                        >
                            <circle
                                className="opacity-25"
                                cx="12"
                                cy="12"
                                r="10"
                                stroke="currentColor"
                                strokeWidth="4"
                            ></circle>
                            <path
                                className="opacity-75"
                                fill="currentColor"
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            ></path>
                        </svg>
                        <p className="text-gray-500 font-medium">
                            Memuat data mahasiswa...
                        </p>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
}
