import React, { useEffect } from 'react';
import { useForm } from '@inertiajs/react';

export default function EditExpirationModal({ isOpen, onClose, buyer }) {
    // Inisialisasi form Inertia
    const { data, setData, patch, processing, errors, reset, clearErrors } = useForm({
        active_until: '',
    });

    // Otomatis mengisi input tanggal dengan data mahasiswa yang sedang dipilih
    useEffect(() => {
        if (isOpen && buyer) {
            // Memastikan format tanggal adalah YYYY-MM-DD untuk input type="date"
            const dateValue = buyer.active_until ? buyer.active_until.split(' ')[0] : '';
            setData('active_until', dateValue);
        } else {
            reset();
            clearErrors();
        }
    }, [isOpen, buyer]);

    const handleSubmit = (e) => {
        e.preventDefault();
        
        // Mengirim request PATCH ke rute yang sudah kita buat sebelumnya
        patch(`/admin/buyers/${buyer.id}/expiration`, {
            preserveScroll: true,
            onSuccess: () => {
                onClose(); // Tutup modal jika sukses
                reset();
            },
        });
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black/40 backdrop-blur-sm transition-opacity">
            <div className="relative w-full max-w-md p-4">
                <div className="relative bg-white rounded-2xl shadow-xl">
                    
                    {/* Header Modal */}
                    <div className="flex items-center justify-between p-5 border-b border-gray-100">
                        <h3 className="text-lg font-bold text-gray-900">
                            Edit Masa Berlaku
                        </h3>
                        <button onClick={onClose} type="button" className="text-gray-400 bg-transparent hover:bg-gray-100 hover:text-gray-900 rounded-lg text-sm w-8 h-8 ms-auto inline-flex justify-center items-center transition-colors">
                            <svg className="w-3 h-3" fill="none" viewBox="0 0 14 14">
                                <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"/>
                            </svg>
                        </button>
                    </div>

                    {/* Body Modal */}
                    <form onSubmit={handleSubmit} className="p-5">
                        <div className="mb-4">
                            <label htmlFor="active_until" className="block mb-2 text-sm font-medium text-gray-900">
                                Tanggal Berakhir Baru
                            </label>
                            <input 
                                type="date" 
                                id="active_until" 
                                className={`bg-gray-50 border text-gray-900 text-sm rounded-lg focus:ring-[#3949AB] focus:border-[#3949AB] block w-full p-2.5 outline-none transition-colors ${errors.active_until ? 'border-red-500' : 'border-gray-300'}`}
                                value={data.active_until}
                                onChange={(e) => setData('active_until', e.target.value)}
                                required 
                            />
                            {errors.active_until && (
                                <p className="mt-2 text-xs text-red-600">{errors.active_until}</p>
                            )}
                        </div>
                        
                        <p className="text-xs text-gray-500 mb-6 leading-relaxed">
                            Pilih tanggal baru untuk memperpanjang atau memperpendek masa aktif akun mahasiswa <span className="font-semibold text-gray-700">{buyer?.name}</span>.
                        </p>

                        {/* Footer Modal */}
                        <div className="flex items-center justify-end gap-3">
                            <button 
                                type="button" 
                                onClick={onClose} 
                                className="py-2.5 px-5 text-sm font-medium text-gray-700 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-50 hover:text-[#3949AB] transition-colors"
                            >
                                Batal
                            </button>
                            <button 
                                type="submit" 
                                disabled={processing}
                                className="text-white bg-[#3949AB] hover:bg-blue-800 font-medium rounded-lg text-sm px-5 py-2.5 text-center transition-colors disabled:opacity-70 flex items-center gap-2"
                            >
                                {processing && (
                                    <svg className="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                                )}
                                Simpan Perubahan
                            </button>
                        </div>
                    </form>

                </div>
            </div>
        </div>
    );
}