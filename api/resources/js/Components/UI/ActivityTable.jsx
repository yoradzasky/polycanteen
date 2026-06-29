import { useState, useMemo } from 'react';
import aktivitasIcon from '@/Components/UI/aktivitas.svg';
import registrasiIcon from '@/Components/UI/registrasi.svg';

// Fungsi untuk membuat deretan angka pagination dengan ellipsis (...)
const getPaginationRange = (current, total) => {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  if (current <= 4) {
    return [1, 2, 3, 4, 5, '...', total];
  }

  if (current >= total - 3) {
    return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
  }

  return [1, '...', current - 1, current, current + 1, '...', total];
};

export default function ActivityTable({ aktivitas = [] }) {
  const [currentPage, setCurrentPage] = useState(1);
  const [filterStatus, setFilterStatus] = useState('semua');
  const [filterTipe, setFilterTipe] = useState('semua');
  const itemsPerPage = 8;

  // Fungsi untuk mendapatkan ikon berdasarkan tipe aktivitas
  const getActivityIcon = (tipeAktivitas) => {
    return tipeAktivitas === 'transaksi' ? aktivitasIcon : registrasiIcon;
  };

  // Fungsi untuk mendapatkan badge warna status
  const getStatusBadge = (status) => {
    const statusLower = status?.toLowerCase() || '';
    if (statusLower === 'selesai' || statusLower === 'sukses') {
      return 'bg-emerald-100 text-emerald-700';
    } else if (statusLower === 'menunggu' || statusLower === 'pending' || statusLower === 'menunggu konfirmasi' || statusLower === 'menunggu pembayaran') {
      return 'bg-gray-100 text-gray-700';
    } else if (statusLower === 'dibayar' || statusLower === 'diproses') {
      return 'bg-blue-100 text-blue-700';
    } else if (statusLower === 'dimasak') {
      return 'bg-orange-100 text-orange-700';
    } else if (statusLower === 'dalam perjalanan' || statusLower === 'diantar') {
      return 'bg-indigo-100 text-indigo-700';
    } else if (statusLower === 'ditolak' || statusLower === 'cancel' || statusLower === 'dibatalkan') {
      return 'bg-red-100 text-red-700';
    }
    return 'bg-gray-100 text-gray-700';
  };

  // Filter data berdasarkan pilihan
  const filteredAktivitas = useMemo(() => {
    return aktivitas.filter((item) => {
      const statusMatch = filterStatus === 'semua' || item.status.toLowerCase() === filterStatus.toLowerCase();
      const tipeMatch = filterTipe === 'semua' || item.tipeAktivitas === filterTipe;
      return statusMatch && tipeMatch;
    });
  }, [aktivitas, filterStatus, filterTipe]);

  // Hitung pagination
  const totalPages = Math.ceil(filteredAktivitas.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedAktivitas = filteredAktivitas.slice(startIndex, startIndex + itemsPerPage);

  // Reset ke halaman 1 ketika filter berubah
  const handleFilterChange = (setter, value) => {
    setter(value);
    setCurrentPage(1);
  };

  // Ambil daftar kantin unik dari data
  const kantinList = useMemo(() => {
    const kantins = new Set(aktivitas.map(a => a.kantin).filter(k => k && k !== '-'));
    return Array.from(kantins);
  }, [aktivitas]);

  return (
    <section className="w-full">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-lg font-semibold text-gray-900">Aktivitas Terbaru</h2>
        
        {/* Filter Section */}
        <div className="flex gap-4">
          <div className="flex items-center gap-2">
            <label className="text-sm font-medium text-gray-700">Status:</label>
            <select
              value={filterStatus}
              onChange={(e) => handleFilterChange(setFilterStatus, e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm bg-white"
            >
              <option value="semua">Semua Status</option>
              <option value="selesai">Selesai</option>
              <option value="diproses">Diproses</option>
              <option value="ditolak">Ditolak</option>
            </select>
          </div>
          
          <div className="flex items-center gap-2">
            <label className="text-sm font-medium text-gray-700">Tipe:</label>
            <select
              value={filterTipe}
              onChange={(e) => handleFilterChange(setFilterTipe, e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm bg-white"
            >
              <option value="semua">Semua Tipe</option>
              <option value="transaksi">Transaksi Pembelian</option>
              <option value="registrasi">Registrasi Akun</option>
            </select>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto rounded-lg border border-gray-200">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b-2 border-gray-200 bg-gray-50">
              <th className="px-6 py-4 text-left font-medium text-gray-700">NAMA</th>
              <th className="px-6 py-4 text-left font-medium text-gray-700">AKTIVITAS</th>
              <th className="px-6 py-4 text-left font-medium text-gray-700">KANTIN</th>
              <th className="px-6 py-4 text-left font-medium text-gray-700">JUMLAH</th>
              <th className="px-6 py-4 text-left font-medium text-gray-700">TANGGAL</th>
              <th className="px-6 py-4 text-left font-medium text-gray-700">STATUS</th>
            </tr>
          </thead>
          <tbody>
            {paginatedAktivitas.length > 0 ? (
              paginatedAktivitas.map((item, index) => (
                <tr key={item.id || index} className="border-b-2 border-gray-200 hover:bg-gray-50 transition">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <img 
                        src={item.fotoProfile} 
                        alt={item.nama} 
                        className="w-8 h-8 rounded-full object-cover"
                      />
                      <div>
                        <p className="font-medium text-gray-900">{item.nama}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <img 
                        src={getActivityIcon(item.tipeAktivitas)} 
                        alt={item.tipe} 
                        className="w-5 h-5 object-contain"
                      />
                      <span className="text-gray-900">{item.tipe}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-900">{item.kantin}</td>
                  <td className="px-6 py-4 text-gray-900">{item.jumlah}</td>
                  <td className="px-6 py-4 text-gray-700">{item.tanggal}</td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadge(item.status)}`}>
                      {item.status.charAt(0).toUpperCase() + item.status.slice(1)}
                    </span>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="6" className="px-6 py-8 text-center text-gray-500">
                  Tidak ada aktivitas dengan filter yang dipilih
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between mt-6">
        <p className="text-sm text-gray-600">
          Menampilkan {paginatedAktivitas.length > 0 ? startIndex + 1 : 0} - {Math.min(startIndex + itemsPerPage, filteredAktivitas.length)} dari {filteredAktivitas.length} aktivitas
        </p>
        <div className="flex gap-2">
          <button
            onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
            disabled={currentPage === 1}
            className="px-3 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            ← Sebelumnya
          </button>
          
          {getPaginationRange(currentPage, totalPages).map((page, index) => (
            page === '...' ? (
              <span key={`ellipsis-${index}`} className="px-4 py-2 text-gray-500">
                ...
              </span>
            ) : (
              <button
                key={index}
                onClick={() => setCurrentPage(page)}
                className={`px-3 py-2 rounded-lg text-sm font-medium transition ${
                  currentPage === page
                    ? 'bg-blue-600 text-white'
                    : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
                }`}
              >
                {page}
              </button>
            )
          ))}
          
          <button
            onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
            disabled={currentPage === totalPages || totalPages === 0}
            className="px-3 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Selanjutnya →
          </button>
        </div>
      </div>
    </section>
  );
}