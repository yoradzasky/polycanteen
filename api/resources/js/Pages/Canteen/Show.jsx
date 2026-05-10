import AdminLayout from '@/Layouts/AdminLayout';
import { Head, Link, router } from '@inertiajs/react';
import { useState } from 'react';
import { AreaChart, Area, ResponsiveContainer, Tooltip } from 'recharts';
import DeleteConfirmModal from '@/Components/DeleteConfirmModal';

function formatRupiah(a) {
    if (!a && a !== 0) return 'Rp 0';
    if (a >= 1e9) {
        const v = a / 1e9;
        return `Rp ${v % 1 === 0 ? v : v.toFixed(1).replace('.', ',')} M`;
    }
    if (a >= 1e6) {
        const v = a / 1e6;
        return `Rp ${v % 1 === 0 ? v : v.toFixed(1).replace('.', ',')} jt`;
    }
    return `Rp ${a.toLocaleString('id-ID')}`;
}

function formatRupiahPenuh(a) {
    if (!a && a !== 0) return 'Rp 0';
    return `Rp ${Number(a).toLocaleString('id-ID')}`;
}

function formatTanggal(iso) {
    if (!iso) return '-';
    const b = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    const d = new Date(iso);
    return `${d.getDate()} ${b[d.getMonth()]} ${d.getFullYear()}`;
}

function formatTanggalLengkap(iso) {
    if (!iso) return '-';
    const hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const b = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    const d = new Date(iso);
    return `${hari[d.getDay()]}, ${d.getDate()} ${b[d.getMonth()]} ${d.getFullYear()}`;
}

function formatAngka(n) {
    if (!n && n !== 0) return '0';
    return Number(n).toLocaleString('id-ID');
}

function getInisial(nama) {
    if (!nama) return '?';
    return nama.split(' ').filter(Boolean).map(w => w[0]).slice(0, 2).join('').toUpperCase();
}

export default function Show({ kantin, total_penjualan, total_menu_terjual, menus, sales_activity }) {
    const [aktPage, setAktPage] = useState(1);
    const [showDelete, setShowDelete] = useState(false);
    const [isDeleting, setIsDeleting] = useState(false);
    const AKT_PER_PAGE = 5;
    const aktivitas = sales_activity || [];
    const aktSliced = aktivitas.slice((aktPage - 1) * AKT_PER_PAGE, aktPage * AKT_PER_PAGE);
    const aktTotalPage = Math.ceil(aktivitas.length / AKT_PER_PAGE) || 1;
    const aktFrom = (aktPage - 1) * AKT_PER_PAGE + 1;
    const aktTo = Math.min(aktPage * AKT_PER_PAGE, aktivitas.length);
    const owner = kantin?.pemilik;
    const chartData = [...(aktivitas || [])].reverse();
    const isBuka = kantin?.status_toko === 'buka';

    const handleMenuPage = (page) => { router.get(route('admin.canteens.show', kantin.id), { menu_page: page }, { preserveState: true, replace: true }) };

    const meta = menus?.meta || menus || {};
    const menuData = menus?.data || [];

    return (
        <AdminLayout title="Detail Kantin" description={
            <div className="flex items-center gap-2 text-xs">
                <Link href={route('admin.canteens.index')} className="text-blue-600 hover:underline font-medium">Daftar Kantin</Link>
                <span className="text-gray-400">›</span>
                <span className="text-gray-500">Detail</span>
            </div>
        } rightContent={
            <div className="flex items-center gap-3">
                <Link href={route('admin.canteens.edit', kantin.id)} className="inline-flex items-center gap-2 px-5 py-2.5 bg-[#2d3a8c] hover:bg-[#252f73] text-white text-sm font-semibold rounded-xl transition-all">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
                    Edit Kantin
                </Link>
                <button onClick={() => setShowDelete(true)} className="inline-flex items-center gap-2 px-5 py-2.5 bg-red-600 hover:bg-red-700 text-white text-sm font-semibold rounded-xl transition-all">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" /></svg>
                    Hapus Kantin
                </button>
            </div>
        }>
            <Head title="Detail Kantin" />
            <div className="px-8 py-7 space-y-6">


                {/* §2 Profil Card */}
                <div className="bg-white rounded-2xl border border-gray-100 p-6">
                    <div className="flex items-center gap-8 flex-wrap">
                        {kantin?.logo_path ? (
                            <img src={kantin.logo_path} alt={kantin.nama_kantin} className="w-16 h-16 rounded-2xl object-cover flex-shrink-0" />
                        ) : (
                            <div className="w-16 h-16 bg-[#2d3a8c] rounded-2xl flex items-center justify-center flex-shrink-0">
                                <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.993 2.993 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72" /></svg>
                            </div>
                        )}
                        <div className="flex-1 grid grid-cols-2 md:grid-cols-5 gap-6">
                            <div><p className="text-xs text-gray-400 mb-1">Nama Kantin</p><p className="text-sm font-bold text-gray-900">{kantin?.nama_kantin}</p></div>
                            <div className="flex items-center gap-2"><div className="w-8 h-8 bg-orange-100 rounded-full flex items-center justify-center"><span className="text-xs font-bold text-orange-600">{getInisial(owner?.nama_pemilik)}</span></div><div><p className="text-xs text-gray-400 mb-1">Nama Pemilik</p><p className="text-sm font-semibold text-gray-900">{owner?.nama_pemilik || '-'}</p></div></div>
                            <div><p className="text-xs text-gray-400 mb-1">Email / Kontak</p><p className="text-sm text-blue-600">{owner?.user?.email || '-'}</p><p className="text-xs text-gray-400">{owner?.no_hp || owner?.no_telp || '-'}</p></div>
                            <div><p className="text-xs text-gray-400 mb-1">Lokasi</p><div className="flex items-center gap-1"><svg className="w-4 h-4 text-blue-500" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd" /></svg><p className="text-sm font-semibold text-gray-900">{kantin?.lokasi_lengkap || kantin?.lokasi_lengkap || '-'}</p></div><p className="text-xs text-gray-400 ml-5">{kantin?.lokasi_kampus || ''}</p></div>
                            <div><p className="text-xs text-gray-400 mb-1">Status</p><span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${isBuka ? 'bg-emerald-50 text-emerald-600' : 'bg-red-50 text-red-600'}`}><span className={`w-1.5 h-1.5 rounded-full ${isBuka ? 'bg-emerald-500' : 'bg-red-500'}`} />{isBuka ? 'Buka' : 'Tutup'}</span></div>
                        </div>
                    </div>
                </div>

                {/* §3 Stats Cards + Sidebar */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="bg-white rounded-2xl border border-gray-100 p-6 relative overflow-hidden">
                        <div className="absolute top-4 right-4 w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center"><svg className="w-5 h-5 text-indigo-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg></div>
                        <p className="text-xs text-gray-400 font-medium">Total Penjualan</p>
                        <p className="text-3xl font-bold text-gray-900 mt-1">{formatRupiah(total_penjualan || 0)}</p>
                        <div className="mt-4 h-16"><ResponsiveContainer width="100%" height="100%"><AreaChart data={chartData}><defs><linearGradient id="gradBlue" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#6366f1" stopOpacity={0.15} /><stop offset="100%" stopColor="#6366f1" stopOpacity={0} /></linearGradient></defs><Area type="monotone" dataKey="total_pendapatan" stroke="#6366f1" strokeWidth={2} fill="url(#gradBlue)" /><Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} formatter={v => formatRupiahPenuh(v)} labelFormatter={l => formatTanggal(l)} /></AreaChart></ResponsiveContainer></div>
                    </div>
                    <div className="bg-white rounded-2xl border border-gray-100 p-6 relative overflow-hidden">
                        <div className="absolute top-4 right-4 w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center"><svg className="w-5 h-5 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6m0 0v6m0-6h6m-6 0H6" /></svg></div>
                        <p className="text-xs text-gray-400 font-medium">Menu Terjual</p>
                        <p className="text-3xl font-bold text-gray-900 mt-1">{formatAngka(total_menu_terjual || 0)}</p>
                        <div className="mt-4 h-16"><ResponsiveContainer width="100%" height="100%"><AreaChart data={chartData}><defs><linearGradient id="gradGreen" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#22c55e" stopOpacity={0.15} /><stop offset="100%" stopColor="#22c55e" stopOpacity={0} /></linearGradient></defs><Area type="monotone" dataKey="jumlah_pesanan" stroke="#22c55e" strokeWidth={2} fill="url(#gradGreen)" /><Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} formatter={v => `${v} pesanan`} labelFormatter={l => formatTanggal(l)} /></AreaChart></ResponsiveContainer></div>
                    </div>
                    {/* §5 Sidebar Info */}
                    <div className="bg-white rounded-2xl border border-gray-100 p-6 h-fit">
                        <h3 className="text-base font-bold text-gray-900 mb-5">Informasi Tambahan</h3>
                        <div className="space-y-4">
                            <div className="flex items-center justify-between"><div className="flex items-center gap-2"><div className="w-8 h-8 bg-blue-50 rounded-lg flex items-center justify-center"><svg className="w-4 h-4 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg></div><span className="text-sm text-gray-600">Tgl. Bergabung</span></div><span className="text-sm font-semibold text-gray-900">{formatTanggal(kantin?.created_at)}</span></div>
                            <div className="flex items-center justify-between"><div className="flex items-center gap-2"><div className="w-8 h-8 bg-yellow-50 rounded-lg flex items-center justify-center"><svg className="w-4 h-4 text-yellow-500" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" /></svg></div><span className="text-sm text-gray-600">Rating</span></div><div className="flex items-center gap-1"><span className="text-sm font-semibold text-gray-900">{kantin?.rating || '–'}</span>{kantin?.rating && <div className="flex gap-0.5">{[1, 2, 3, 4, 5].map(s => <svg key={s} className={`w-3.5 h-3.5 ${s <= Math.round(kantin.rating) ? 'text-yellow-400' : 'text-gray-200'}`} fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" /></svg>)}</div>}</div></div>
                            <div className="flex items-center justify-between"><div className="flex items-center gap-2"><div className="w-8 h-8 bg-purple-50 rounded-lg flex items-center justify-center"><svg className="w-4 h-4 text-purple-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" /></svg></div><span className="text-sm text-gray-600">Jumlah Karyawan</span></div><span className="text-sm font-semibold text-gray-900">{kantin?.pegawai?.length || 0} orang</span></div>
                        </div>
                    </div>
                </div>

                {/* §4 Menu Table */}
                <div className="bg-white rounded-2xl border border-gray-100">
                    <div className="px-6 py-5 border-b border-gray-100"><h2 className="text-base font-bold text-gray-900">Daftar Menu</h2><p className="text-xs text-gray-400 mt-0.5">{meta.total || 0} menu terdaftar di kantin ini</p></div>
                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[650px]">
                            <thead><tr className="border-b border-gray-100">
                                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase">Foto Menu</th>
                                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase">Nama Menu</th>
                                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase">Harga</th>
                                <th className="text-center px-6 py-3 text-xs font-semibold text-gray-400 uppercase">Status</th>
                                <th className="text-center px-6 py-3 text-xs font-semibold text-gray-400 uppercase">Total Terjual</th>
                            </tr></thead>
                            <tbody className="divide-y divide-gray-50">
                                {menuData.length > 0 ? menuData.map(m => (
                                    <tr key={m.id} className="hover:bg-gray-50/50 transition-colors">
                                        <td className="px-6 py-3">{m.foto_menu ? <img src={m.foto_menu} alt={m.nama_item} className="w-12 h-12 rounded-xl object-cover" /> : <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center"><span className="text-xs font-bold text-orange-600">{getInisial(m.nama_item)}</span></div>}</td>
                                        <td className="px-6 py-3"><p className="text-sm font-semibold text-gray-900">{m.nama_item}</p><p className="text-xs text-gray-400">{m.kategori}</p></td>
                                        <td className="px-6 py-3 text-sm text-gray-700">{formatRupiahPenuh(m.harga)}</td>
                                        <td className="px-6 py-3 text-center"><span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold ${m.status_stok ? 'bg-emerald-50 text-emerald-600' : 'bg-red-50 text-red-600'}`}><span className={`w-1.5 h-1.5 rounded-full ${m.status_stok ? 'bg-emerald-500' : 'bg-red-500'}`} />{m.status_stok ? 'Tersedia' : 'Habis'}</span></td>
                                        <td className="px-6 py-3 text-center text-sm font-semibold text-gray-700">{formatAngka(m.pesanan_details_sum_jumlah_pesanan || 0)}</td>
                                    </tr>
                                )) : <tr><td colSpan={5} className="px-6 py-12 text-center text-sm text-gray-400">Belum ada menu</td></tr>}
                            </tbody>
                        </table>
                    </div>
                    <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100">
                        <p className="text-sm text-gray-500">Menampilkan <span className="font-semibold text-gray-700">{meta.from || 0}–{meta.to || 0}</span> dari <span className="font-semibold text-gray-700">{meta.total || 0}</span> menu</p>
                        <div className="flex items-center gap-1">
                            <button onClick={() => handleMenuPage(Math.max(1, (meta.current_page || 1) - 1))} disabled={(meta.current_page || 1) <= 1} className="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 disabled:opacity-30">‹</button>
                            {Array.from({ length: meta.last_page || 1 }, (_, i) => i + 1).map(p => (
                                <button key={p} onClick={() => handleMenuPage(p)} className={`w-8 h-8 flex items-center justify-center rounded-lg text-sm transition-colors ${p === (meta.current_page || 1) ? 'bg-[#3852b4] text-white font-semibold' : 'text-gray-600 hover:bg-gray-100'}`}>{p}</button>
                            ))}
                            <button onClick={() => handleMenuPage(Math.min(meta.last_page || 1, (meta.current_page || 1) + 1))} disabled={(meta.current_page || 1) >= (meta.last_page || 1)} className="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 disabled:opacity-30">›</button>
                        </div>
                    </div>
                </div>

                {/* §6 Sales Activity */}
                <div className="bg-white rounded-2xl border border-gray-100">
                    <div className="px-6 py-5 border-b border-gray-100"><h2 className="text-base font-bold text-gray-900">Aktivitas Penjualan</h2><p className="text-xs text-gray-400 mt-0.5">Riwayat transaksi harian kantin</p></div>
                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[550px]">
                            <thead><tr className="border-b border-gray-100">
                                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase"><span className="inline-flex items-center gap-1">Tanggal <span className="text-gray-300">↕</span></span></th>
                                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase"><span className="inline-flex items-center gap-1">Jumlah Pesanan <span className="text-gray-300">↕</span></span></th>
                                <th className="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase"><span className="inline-flex items-center gap-1">Total Pendapatan <span className="text-gray-300">↕</span></span></th>
                            </tr></thead>
                            <tbody className="divide-y divide-gray-50">
                                {aktSliced.map((item, i) => (
                                    <tr key={i} className="hover:bg-gray-50/50 transition-colors">
                                        <td className="px-6 py-3"><div className="flex items-center gap-2"><div className="w-8 h-8 bg-blue-50 rounded-lg flex items-center justify-center"><svg className="w-4 h-4 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg></div><span className="text-sm text-gray-700">{formatTanggalLengkap(item.tanggal)}</span></div></td>
                                        <td className="px-6 py-3 text-sm text-gray-700">{item.jumlah_pesanan} pesanan</td>
                                        <td className="px-6 py-3 text-sm font-semibold text-gray-900">{formatRupiahPenuh(item.total_pendapatan)}</td>
                                    </tr>
                                ))}
                                {aktSliced.length === 0 && <tr><td colSpan={3} className="px-6 py-12 text-center text-sm text-gray-400">Belum ada data aktivitas</td></tr>}
                            </tbody>
                        </table>
                    </div>
                    <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100">
                        <p className="text-sm text-gray-500">Menampilkan <span className="font-semibold text-gray-700">{aktivitas.length > 0 ? aktFrom : 0}–{aktivitas.length > 0 ? aktTo : 0}</span> dari <span className="font-semibold text-gray-700">{aktivitas.length}</span> hari</p>
                        <div className="flex items-center gap-1">
                            <button onClick={() => setAktPage(p => Math.max(1, p - 1))} disabled={aktPage <= 1} className="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 disabled:opacity-30">‹</button>
                            {Array.from({ length: aktTotalPage }, (_, i) => i + 1).map(p => (
                                <button key={p} onClick={() => setAktPage(p)} className={`w-8 h-8 flex items-center justify-center rounded-lg text-sm transition-colors ${p === aktPage ? 'bg-[#3852b4] text-white font-semibold' : 'text-gray-600 hover:bg-gray-100'}`}>{p}</button>
                            ))}
                            <button onClick={() => setAktPage(p => Math.min(aktTotalPage, p + 1))} disabled={aktPage >= aktTotalPage} className="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 disabled:opacity-30">›</button>
                        </div>
                    </div>
                </div>

            </div>

            <DeleteConfirmModal
                isOpen={showDelete}
                onClose={() => setShowDelete(false)}
                namaKantin={kantin.nama_kantin}
                logoPath={kantin.logo_path}
                isDeleting={isDeleting}
                onConfirm={() => {
                    setIsDeleting(true);
                    router.delete(route('admin.canteens.destroy', kantin.id), {
                        onSuccess: () => router.visit(route('admin.canteens.index')),
                        onFinish:  () => setIsDeleting(false),
                    });
                }}
            />
        </AdminLayout>
    );
}
