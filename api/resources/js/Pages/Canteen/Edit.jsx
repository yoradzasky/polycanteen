import AdminLayout from '@/Layouts/AdminLayout';
import { Head, Link, useForm, router, usePage } from '@inertiajs/react';
import { useState } from 'react';
import MapPickerModal from '@/Components/Modals/MapPickerModal';

function FormField({ label, required, helper, error, children }) {
    return (
        <div className="flex flex-col space-y-1.5 w-full">
            {label && (
                <label className="text-sm font-medium text-gray-700">
                    {label} {required && <span className="text-red-500">*</span>}
                </label>
            )}
            {children}
            {helper && !error && <p className="text-xs text-gray-500">{helper}</p>}
            {error && <p className="text-xs text-red-500">{error}</p>}
        </div>
    );
}

function PhoneInput({ value, onChange, placeholder, error }) {
    return (
        <div className="flex w-full">
            <div className="flex items-center justify-center px-3 border border-gray-300 border-r-0 rounded-l-md bg-gray-50 text-gray-600 text-sm">
                +62
            </div>
            <input
                type="text"
                className={`flex-1 border rounded-r-md px-3 py-2 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${error ? 'border-red-500' : 'border-gray-300'
                    }`}
                placeholder={placeholder}
                value={value}
                onChange={onChange}
            />
        </div>
    );
}

export default function Edit({ kantin }) {
    const { props } = usePage();
    const flash = props.flash || {};

    const { data, setData, put, processing, errors, reset } = useForm({
        nama_kantin: kantin.nama_kantin || '',
        lokasi_lengkap: kantin.lokasi_lengkap || '',
        latitude: kantin.latitude ?? '',
        longitude: kantin.longitude ?? '',
        nama_pemilik: kantin.pemilik?.nama_pemilik || '',
        no_telp: kantin.pemilik?.no_telp || '',
        email: kantin.pemilik?.user?.email || '',
        karyawan: (kantin.pegawai || []).map(p => ({
            id: p.id,
            nama_karyawan: p.nama_karyawan || '',
            no_telp: p.no_telp || '',
            email: p.user?.email || '',
        })),
    });

    const [showMap, setShowMap] = useState(false);

    const tambahKaryawan = () => {
        setData('karyawan', [
            ...data.karyawan,
            { nama_karyawan: '', no_telp: '', email: '' }
        ]);
    };

    const updateKaryawan = (index, field, value) => {
        const updated = [...data.karyawan];
        updated[index] = { ...updated[index], [field]: value };
        setData('karyawan', updated);
    };

    const hapusKaryawan = (index) => {
        setData('karyawan', data.karyawan.filter((_, i) => i !== index));
    };

    const handleSubmit = () => {
        put(route('admin.canteens.update', { id: kantin.id, from: props.from || 'index' }));
    };

    return (
        <AdminLayout
            title="Edit Kantin"
            description={
                <span className="flex items-center space-x-1.5">
                    <Link href={route('admin.canteens.index')} className="text-blue-600 hover:underline font-medium">
                        Daftar Kantin
                    </Link>
                    {props.from === 'show' && (
                        <>
                            <span className="text-gray-300">›</span>
                            <Link href={route('admin.canteens.show', kantin.id)} className="text-blue-600 hover:underline font-medium">
                                Detail
                            </Link>
                        </>
                    )}
                    <span className="text-gray-300">›</span>
                    <span className="text-gray-500">Edit</span>
                </span>
            }
            rightContent={null}
        >
            <Head title="Edit Kantin" />

            <div className="min-h-screen bg-[#f8fafc] py-8 px-4 sm:px-6 lg:px-8 font-sans">
                {/* Form Container */}
                <div className="max-w-3xl mx-auto bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden relative">

                    {/* Banner Flash Message */}
                    {flash.success && (
                        <div className="bg-green-50 border-b border-green-200 p-4">
                            <p className="text-sm text-green-800">{flash.success}</p>
                        </div>
                    )}
                    {flash.error && (
                        <div className="bg-red-50 border-b border-red-200 p-4">
                            <p className="text-sm text-red-800">{flash.error}</p>
                        </div>
                    )}

                    {/* Header Form Card */}
                    <div className="p-6 border-b border-gray-100 bg-gray-50/50">
                        <div className="flex items-center space-x-4">
                            <div className="bg-indigo-100 p-3 rounded-xl text-indigo-600 shadow-sm">
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                                </svg>
                            </div>
                            <div className="pr-20">
                                <h2 className="text-lg font-bold text-gray-800">Formulir Pendaftaran Kantin</h2>
                                <p className="text-sm text-gray-500 mt-0.5">Perbarui informasi kantin <span className="text-blue-600 font-medium">{kantin.nama_kantin}</span> di bawah ini</p>
                            </div>
                        </div>
                    </div>

                    <div className="p-6 md:p-8 space-y-12">
                        {/* SECTION 1: Informasi Kantin */}
                        <div className="space-y-6">
                            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
                                <div className="flex items-center space-x-3">
                                    <div className="bg-blue-100 p-2 rounded-lg text-blue-600">
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
                                    </div>
                                    <div>
                                        <h3 className="text-base font-semibold text-gray-800">Informasi Kantin</h3>
                                        <p className="text-xs text-gray-500">Data dasar dan identitas kantin</p>
                                    </div>
                                </div>
                                <span className="px-3 py-1 text-xs font-semibold text-blue-700 bg-blue-50 border border-blue-100 rounded-full">Bagian 1 dari 3</span>
                            </div>

                            <div className="space-y-5">
                                <FormField label="Nama Kantin" required helper="Nama yang akan ditampilkan kepada pembeli" error={errors.nama_kantin}>
                                    <div className="relative">
                                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                        </div>
                                        <input type="text" className={`w-full pl-10 border rounded-md py-2 px-3 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${errors.nama_kantin ? 'border-red-500' : 'border-gray-300'}`} placeholder="Kantin Mbok Jum" value={data.nama_kantin} onChange={e => setData('nama_kantin', e.target.value)} />
                                    </div>
                                </FormField>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                                    <FormField label="Lokasi Kantin" required helper="Lokasi fisik kantin di dalam kampus" error={errors.latitude || errors.longitude}>
                                        <button type="button" onClick={() => setShowMap(true)} className="w-full border-2 border-dashed border-blue-300 rounded-lg py-3 px-4 flex items-center gap-2 text-blue-600 hover:bg-blue-50 transition-colors text-sm font-medium">
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                            <span>Pilih Lokasi di Map</span>
                                            {data.latitude && (
                                                <span className="ml-auto text-xs text-gray-500 font-normal">
                                                    {parseFloat(data.latitude).toFixed(5)}, {parseFloat(data.longitude).toFixed(5)}
                                                </span>
                                            )}
                                        </button>
                                    </FormField>

                                    <FormField label="Lokasi Gedung" helper="Contoh: Gedung A, Lantai 2" error={errors.lokasi_lengkap}>
                                        <div className="relative">
                                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m3-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                                            </div>
                                            <input type="text" className={`w-full pl-10 border rounded-lg py-2.5 px-3 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${errors.lokasi_lengkap ? 'border-red-500' : 'border-gray-300'}`} placeholder="Gedung A, Lantai 2" value={data.lokasi_lengkap} onChange={e => setData('lokasi_lengkap', e.target.value)} />
                                        </div>
                                    </FormField>
                                </div>

                                {/* MapPickerModal */}
                                <MapPickerModal
                                    isOpen={showMap}
                                    onClose={() => setShowMap(false)}
                                    initialLat={data.latitude ? parseFloat(data.latitude) : undefined}
                                    initialLng={data.longitude ? parseFloat(data.longitude) : undefined}
                                    onConfirm={({ lat, lng }) => {
                                        setData(prev => ({
                                            ...prev,
                                            latitude: lat.toString(),
                                            longitude: lng.toString(),
                                        }));
                                        setShowMap(false);
                                    }}
                                />
                            </div>
                        </div>

                        {/* SECTION 2: Data Pemilik */}
                        <div className="space-y-6">
                            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
                                <div className="flex items-center space-x-3">
                                    <div className="bg-orange-100 p-2 rounded-lg text-orange-600">
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                                    </div>
                                    <div>
                                        <h3 className="text-base font-semibold text-gray-800">Data Pemilik</h3>
                                        <p className="text-xs text-gray-500">Informasi pemilik atau pengelola kantin</p>
                                    </div>
                                </div>
                                <span className="px-3 py-1 text-xs font-semibold text-orange-700 bg-orange-50 border border-orange-100 rounded-full">Bagian 2 dari 3</span>
                            </div>

                            <div className="space-y-5">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <FormField label="Nama Pemilik" required error={errors.nama_pemilik}>
                                        <div className="relative">
                                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                                            </div>
                                            <input type="text" className={`w-full pl-10 border rounded-md py-2 px-3 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${errors.nama_pemilik ? 'border-red-500' : 'border-gray-300'}`} placeholder="Nama lengkap pemilik" value={data.nama_pemilik} onChange={e => setData('nama_pemilik', e.target.value)} />
                                        </div>
                                    </FormField>

                                    <FormField label="Nomor HP" required error={errors.no_telp}>
                                        <PhoneInput value={data.no_telp} onChange={e => setData('no_telp', e.target.value.replace(/[^0-9]/g, ''))} placeholder="08XX-XXXX-XXXX" error={errors.no_telp} />
                                    </FormField>
                                </div>

                                <FormField label="Email Pemilik" required helper="Email untuk korespondensi dengan admin sistem" error={errors.email}>
                                    <div className="relative">
                                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                                        </div>
                                        <input type="email" className={`w-full pl-10 border rounded-md py-2 px-3 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${errors.email ? 'border-red-500' : 'border-gray-300'}`} placeholder="email@contoh.com" value={data.email} onChange={e => setData('email', e.target.value)} />
                                    </div>
                                </FormField>
                            </div>
                        </div>

                        {/* SECTION 3: Data Karyawan */}
                        <div className="space-y-6">
                            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
                                <div className="flex items-center space-x-3">
                                    <div className="bg-green-100 p-2 rounded-lg text-green-600">
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                    </div>
                                    <div>
                                        <h3 className="text-base font-semibold text-gray-800">Data Karyawan</h3>
                                        <p className="text-xs text-gray-500">Informasi karyawan kantin</p>
                                    </div>
                                </div>
                                <span className="px-3 py-1 text-xs font-semibold text-green-700 bg-green-50 border border-green-100 rounded-full">Bagian 3 dari 3</span>
                            </div>

                            <div className="bg-blue-50 border border-blue-100 rounded-lg p-4 flex items-start space-x-3">
                                <div className="text-blue-500 mt-0.5">
                                    <svg fill="currentColor" viewBox="0 0 20 20" className="w-5 h-5"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"></path></svg>
                                </div>
                                <div>
                                    <h4 className="text-sm font-semibold text-blue-800">Informasi Akun</h4>
                                    <p className="text-sm text-blue-600 mt-0.5">Akun ini akan digunakan oleh karyawan kantin untuk mengakses dashboard pengelolaan (Opsional).</p>
                                </div>
                            </div>

                            <div className="space-y-4">
                                {data.karyawan.map((item, index) => (
                                    <div key={index} className="p-5 border border-gray-200 rounded-lg relative bg-white shadow-sm">
                                        <button type="button" onClick={() => hapusKaryawan(index)} className="absolute top-4 right-4 text-gray-400 hover:text-red-500 transition-colors bg-gray-50 hover:bg-red-50 p-1.5 rounded-md" title="Hapus Karyawan">
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                                        </button>

                                        <div className="mb-4 flex items-center space-x-2">
                                            <span className="w-6 h-6 rounded-full bg-gray-100 text-gray-600 flex items-center justify-center text-xs font-bold">{index + 1}</span>
                                            <h5 className="text-sm font-semibold text-gray-700">Detail Karyawan {item.id ? '(Existing)' : '(Baru)'}</h5>
                                        </div>

                                        <div className="space-y-4">
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                <FormField label="Nama Karyawan" required error={errors[`karyawan.${index}.nama_karyawan`]}>
                                                    <div className="relative">
                                                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                                                        </div>
                                                        <input type="text" className={`w-full pl-10 border rounded-md py-2 px-3 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${errors[`karyawan.${index}.nama_karyawan`] ? 'border-red-500' : 'border-gray-300'}`} placeholder="Nama lengkap karyawan" value={item.nama_karyawan} onChange={e => updateKaryawan(index, 'nama_karyawan', e.target.value)} />
                                                    </div>
                                                </FormField>

                                                <FormField label="Nomor HP" required error={errors[`karyawan.${index}.no_telp`]}>
                                                    <PhoneInput value={item.no_telp} onChange={e => updateKaryawan(index, 'no_telp', e.target.value.replace(/[^0-9]/g, ''))} placeholder="08XX-XXXX-XXXX" error={errors[`karyawan.${index}.no_telp`]} />
                                                </FormField>
                                            </div>

                                            <FormField label="Email Karyawan" required error={errors[`karyawan.${index}.email`]}>
                                                <div className="relative">
                                                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                                                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                                                    </div>
                                                    <input type="email" className={`w-full pl-10 border rounded-md py-2 px-3 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors ${errors[`karyawan.${index}.email`] ? 'border-red-500' : 'border-gray-300'}`} placeholder="email@contoh.com" value={item.email} onChange={e => updateKaryawan(index, 'email', e.target.value)} />
                                                </div>
                                            </FormField>
                                        </div>
                                    </div>
                                ))}

                                <button type="button" onClick={tambahKaryawan} className="w-full flex items-center justify-center space-x-2 py-2.5 text-sm font-medium text-blue-600 bg-white border border-blue-200 rounded-lg hover:bg-blue-50 transition-colors border-dashed border-2">
                                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4"></path></svg>
                                    <span>Tambah Karyawan Baru</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Form Footer */}
                    <div className="px-6 py-5 border-t border-gray-100 bg-gray-50 flex flex-col sm:flex-row items-center justify-between gap-4">
                        <div className="text-xs text-gray-500 flex items-center space-x-1.5">
                            <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            <span>Field bertanda <span className="text-red-500">*</span> wajib diisi</span>
                        </div>
                        <div className="flex items-center space-x-3 w-full sm:w-auto">
                            <Link href={props.from === 'show' ? route('admin.canteens.show', kantin.id) : route('admin.canteens.index')} className="flex-1 sm:flex-none flex justify-center items-center px-4 py-2.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors shadow-sm">
                                × Batal
                            </Link>
                            <button type="button" onClick={handleSubmit} disabled={processing} className="flex-1 sm:flex-none flex justify-center items-center space-x-2 px-5 py-2.5 text-sm font-medium text-white bg-blue-700 border border-transparent rounded-lg hover:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 transition-colors shadow-sm">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"></path></svg>
                                <span>{processing ? 'Menyimpan...' : 'Simpan Perubahan'}</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
}
