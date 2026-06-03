import React, { useState } from 'react';
import { Head, Link, useForm, usePage } from '@inertiajs/react';

// MENGAPA: Komponen input diekstrak menjadi sub-komponen terpisah
// agar kode form utama lebih rapi dan konsisten dalam penerapan Tailwind classes. (Aturan 14)
const FormGroup = ({ label, id, type = 'text', value, onChange, error, placeholder, required = false }) => (
    <div className="mb-6">
        <label htmlFor={id} className="block text-sm font-medium text-gray-700 mb-2">
            {label} {required && <span className="text-red-500" title="Wajib diisi">*</span>}
        </label>
        <input
            id={id}
            type={type}
            value={value}
            onChange={onChange}
            placeholder={placeholder}
            required={required}
            className={`block w-full rounded-xl shadow-sm sm:text-sm transition-colors px-4 py-3 outline-none ${
                error 
                    ? 'border-red-300 text-red-900 placeholder-red-300 focus:ring-red-500 focus:border-red-500 ring-1 ring-red-500' 
                    : 'border-gray-300 focus:ring-indigo-500 focus:border-indigo-500 ring-1 ring-gray-200 hover:ring-gray-300'
            }`}
        />
        {/* MENGAPA: Pesan error dari backend selalu dimunculkan tepat di bawah field yang bermasalah */}
        {error && <p className="mt-2 text-sm text-red-600 font-medium animate-pulse">{error}</p>}
    </div>
);

const AlertMessage = ({ message, type }) => {
    if (!message) return null;
    const bgClass = type === 'success' ? 'bg-green-50 text-green-800 border-green-200' : 'bg-red-50 text-red-800 border-red-200';
    return (
        <div className={`p-4 mb-6 text-sm rounded-xl border shadow-sm ${bgClass}`} role="alert">
            {message}
        </div>
    );
};

export default function Create() {
    // MENGAPA: Inertia useForm mengatur request HTTP (POST) dan tracking form state otomatis.
    // Hindari menggunakan axios/fetch manual ketika routing melibatkan navigasi internal Inertia. (Aturan 10)
    const { data, setData, post, processing, errors, reset } = useForm({
        nama_kantin: '',
        lokasi_lengkap: '',
        nama_pemilik: '',
        email: '',
        nim: '', // Akan dihash backend menjadi default password
        no_telp: '',
    });

    const { flash } = usePage().props;
    
    // MENGAPA: State tambahan khusus untuk error validasi di client sebelum hit backend
    const [clientError, setClientError] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();
        setClientError('');

        // MENGAPA: Validasi client-side diwajibkan untuk menghemat resource server
        // dan mempercepat feedback UI pada form teks panjang. (Aturan 13)
        if (data.nama_kantin.trim().length < 3) {
            setClientError('Nama kantin terlalu singkat, minimal 3 karakter.');
            return;
        }
        if (data.nim.trim().length < 5) {
            setClientError('NIM harus minimal 5 digit untuk memenuhi standar keamanan password.');
            return;
        }

        // MENGAPA: Panggil fungsi POST dari form handler bawaan Inertia.
        post('/admin/canteens', {
            preserveScroll: true,
            onSuccess: () => reset(),
        });
    };

    return (
        <div className="min-h-screen bg-gray-50 py-10 font-sans">
            <Head title="Pendaftaran Kantin Baru" />
            <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
                
                <div className="mb-8">
                    <Link href="/admin/canteens" className="text-sm font-medium text-indigo-600 hover:text-indigo-800 flex items-center transition-colors">
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
                        Kembali ke Daftar Kantin
                    </Link>
                </div>

                <div className="bg-white rounded-2xl shadow-sm ring-1 ring-gray-900/5 overflow-hidden">
                    <div className="px-6 py-8 sm:p-10 border-b border-gray-100 bg-white">
                        <h2 className="text-2xl font-bold text-gray-900">Form Pendaftaran Kantin</h2>
                        <p className="mt-2 text-sm text-gray-500 leading-relaxed">
                            Masukkan data identitas kantin dan profil pengelola utama. Akun login akan dibuatkan secara otomatis.
                        </p>
                    </div>

                    <form onSubmit={handleSubmit} className="px-6 py-8 sm:p-10 bg-gray-50/30">
                        
                        {/* Menampilkan flash dari response server atau dari form validasi client */}
                        <AlertMessage message={flash?.error || clientError} type="error" />

                        <div className="space-y-10">
                            {/* Section 1: Informasi Kantin */}
                            <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
                                <h3 className="text-lg font-bold leading-6 text-gray-900 mb-6 flex items-center">
                                    <span className="w-8 h-8 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center mr-3 text-sm">1</span>
                                    Identitas Kantin
                                </h3>
                                <div className="grid grid-cols-1 gap-y-2 sm:grid-cols-2 sm:gap-x-6 pl-11">
                                    <div className="sm:col-span-2">
                                        <FormGroup 
                                            label="Nama Resmi Kantin" 
                                            id="nama_kantin" 
                                            value={data.nama_kantin} 
                                            onChange={e => setData('nama_kantin', e.target.value)} 
                                            error={errors.nama_kantin} 
                                            placeholder="Misalnya: Nasi Padang Bu Siti"
                                            required
                                        />
                                    </div>
                                    <div className="sm:col-span-2">
                                        <FormGroup 
                                            label="Lokasi atau Keterangan Lapak" 
                                            id="lokasi_lengkap" 
                                            value={data.lokasi_lengkap} 
                                            onChange={e => setData('lokasi_lengkap', e.target.value)} 
                                            error={errors.lokasi_lengkap} 
                                            placeholder="Gedung Direktorat Lantai 2, Blok A"
                                        />
                                    </div>
                                </div>
                            </div>

                            {/* Section 2: Informasi Pemilik */}
                            <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
                                <h3 className="text-lg font-bold leading-6 text-gray-900 mb-6 flex items-center">
                                    <span className="w-8 h-8 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center mr-3 text-sm">2</span>
                                    Profil Pemilik / Pengelola
                                </h3>
                                <div className="grid grid-cols-1 gap-y-2 sm:grid-cols-2 sm:gap-x-6 pl-11">
                                    <div className="sm:col-span-2">
                                        <FormGroup 
                                            label="Nama Lengkap Pemilik" 
                                            id="nama_pemilik" 
                                            value={data.nama_pemilik} 
                                            onChange={e => setData('nama_pemilik', e.target.value)} 
                                            error={errors.nama_pemilik} 
                                            placeholder="Sesuai KTP"
                                            required
                                        />
                                    </div>
                                    <FormGroup 
                                        label="Alamat Email Akun" 
                                        id="email" 
                                        type="email"
                                        value={data.email} 
                                        onChange={e => setData('email', e.target.value)} 
                                        error={errors.email} 
                                        placeholder="email@example.com"
                                        required
                                    />
                                    <FormGroup 
                                        label="Nomor Induk / NIM" 
                                        id="nim" 
                                        value={data.nim} 
                                        onChange={e => setData('nim', e.target.value)} 
                                        error={errors.nim} 
                                        placeholder="Gunakan NIM atau NIK"
                                        required
                                    />
                                    <div className="sm:col-span-2">
                                        <FormGroup 
                                            label="Nomor WhatsApp / Handphone" 
                                            id="no_telp" 
                                            value={data.no_telp} 
                                            onChange={e => setData('no_telp', e.target.value)} 
                                            error={errors.no_telp} 
                                            placeholder="0812xxxxxx"
                                        />
                                    </div>
                                    
                                    <div className="sm:col-span-2 bg-blue-50 text-blue-800 p-5 rounded-xl mt-2 text-sm flex items-start border border-blue-100">
                                        <svg className="w-5 h-5 mr-3 flex-shrink-0 mt-0.5 text-blue-500" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"></path></svg>
                                        <p className="leading-relaxed text-blue-900 font-medium">Sesuai standar arsitektur sistem, <strong>Nomor Induk / NIM</strong> yang Anda masukkan di atas akan otomatis digunakan oleh sistem sebagai <strong>Password Default</strong> untuk login pemilik.</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="mt-10 flex items-center justify-end border-t border-gray-200 pt-6">
                            <Link href="/admin/canteens" className="text-sm font-semibold text-gray-600 hover:text-gray-900 mr-8 transition-colors">
                                Batalkan Pengisian
                            </Link>
                            {/* MENGAPA: Tombol submit memiliki atribut disabled terikat state isProcessing 
                            agar tidak terjadi double request atau klik ganda dari pengguna (Aturan 12) */}
                            <button
                                type="submit"
                                disabled={processing}
                                className={`inline-flex items-center px-6 py-3 border border-transparent text-base font-semibold rounded-xl shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all ${
                                    processing ? 'opacity-70 cursor-not-allowed scale-95' : 'hover:-translate-y-0.5 active:translate-y-0'
                                }`}
                            >
                                {processing ? (
                                    <>
                                        <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                        </svg>
                                        Memproses Data...
                                    </>
                                ) : (
                                    'Daftarkan Kantin'
                                )}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
