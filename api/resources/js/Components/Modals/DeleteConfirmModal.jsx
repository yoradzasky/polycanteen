export default function DeleteConfirmModal({ isOpen, onClose, onConfirm, namaKantin, logoPath, isDeleting = false }) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden border border-gray-100">
        {/* Accent Bar */}
        <div className="h-1.5 w-full bg-red-500"></div>

        <div className="p-5 md:p-6">
          {/* Ikon Tengah */}
          <div className="flex justify-center mb-5">
            <div className="w-14 h-14 bg-red-50 rounded-2xl flex items-center justify-center text-red-500">
              <svg className="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
              </svg>
            </div>
          </div>

          {/* Judul & Subjudul */}
          <div className="text-center mb-5">
            <h2 className="text-xl font-bold text-gray-900 mb-1.5">Hapus Kantin</h2>
            <p className="text-sm text-gray-500">
              Apakah Anda yakin ingin menghapus akun kantin ini?
            </p>
          </div>

          {/* Warning Box */}
          <div className="bg-red-50 rounded-xl p-3 mb-5 flex items-start gap-2.5">
            <svg className="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p className="text-red-600 font-medium text-xs">
              Akun pemilik dan karyawan kantin ini juga akan dihapus.
            </p>
          </div>

          {/* Card Info Kantin */}
          <div className="bg-gray-50 rounded-xl p-3 mb-6 flex items-center gap-3">
            {logoPath ? (
              <img src={logoPath} alt={namaKantin} className="w-10 h-10 rounded-xl object-cover shadow-sm" />
            ) : (
              <div className="w-10 h-10 bg-red-500 rounded-xl flex items-center justify-center flex-shrink-0">
                <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.993 2.993 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72" />
                </svg>
              </div>
            )}
            <span className="font-semibold text-gray-900 text-base">{namaKantin}</span>
          </div>

          {/* Tombol Aksi */}
          <div className="flex items-center gap-3">
            {/* Batal */}
            <button
              onClick={onClose}
              disabled={isDeleting}
              className="flex-1 py-2.5 px-4 rounded-xl border border-gray-200 text-gray-700 text-sm font-semibold hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              × Batal
            </button>

            {/* Hapus */}
            <button
              onClick={onConfirm}
              disabled={isDeleting}
              className="flex-1 py-2.5 px-4 rounded-xl bg-red-500 hover:bg-red-600 text-white text-sm font-semibold transition-colors flex justify-center items-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isDeleting ? (
                <>
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Menghapus...
                </>
              ) : (
                <>
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                  Hapus
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
