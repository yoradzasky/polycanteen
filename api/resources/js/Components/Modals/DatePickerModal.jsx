import React from 'react';

export default function DatePickerModal({ isOpen, onClose, title = "Pilih Tanggal", value, onChange, onConfirm }) {
    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 backdrop-blur-sm transition-opacity">
            <div className="relative w-full max-w-sm p-4">
                <div className="bg-white rounded-2xl shadow-xl p-5">
                    <h3 className="text-base font-bold text-gray-900 mb-4">{title}</h3>
                    
                    <input 
                        type="date" 
                        className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-[#3949AB] focus:border-[#3949AB] block w-full p-2.5 outline-none mb-6"
                        value={value}
                        onChange={(e) => onChange(e.target.value)}
                    />
                    
                    <div className="flex justify-end gap-2">
                        <button 
                            onClick={onClose}
                            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
                        >
                            Batal
                        </button>
                        <button 
                            onClick={onConfirm}
                            className="px-4 py-2 text-sm font-medium text-white bg-[#3949AB] rounded-lg hover:bg-blue-800"
                        >
                            Pilih
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}