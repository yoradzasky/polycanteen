import AdminLayout from '@/Layouts/AdminLayout';
import StatCard from '@/Components/UI/StatCard';
import ActivityTable from '@/Components/UI/ActivityTable';

import transaksiIcon from '@/Components/UI/transaksi.svg'; 
import pembeliIcon from '@/Components/UI/pembeli.svg';
import kantinIcon from '@/Components/UI/kantin.svg';

// 1. Tangkap props dari Laravel di dalam parameter fungsi (destructuring)
export default function Index({ totalTransaksi = 0, totalPembeli = 0, totalKantin = 0, aktivitas = [] }) {
  
  // 2. Fungsi bantuan untuk memformat Rupiah jadi "Jt" (Juta)
  const formatRupiahJuta = (angka) => {
    if (angka >= 1000000) {
      return `Rp ${(angka / 1000000).toFixed(1).replace('.', ',')} Jt`;
    }
    // Jika belum sampai 1 juta, tampilkan format rupiah biasa
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(angka);
  };

  // 3. Masukkan variabel props ke dalam array summaryCards
  const summaryCards = [
    {
      title: "TOTAL TRANSAKSI",
      value: formatRupiahJuta(totalTransaksi), // Angka dinamis!
      iconBg: "bg-emerald-50 text-emerald-500",
      progressColor: "bg-emerald-400",
      icon: <img src={transaksiIcon} alt="Ikon Transaksi" className="w-6 h-6 object-contain" />, 
    },
    {
      title: "TOTAL PEMBELI",
      value: totalPembeli.toLocaleString('id-ID'), // Angka dinamis dengan titik ribuan!
      iconBg: "bg-blue-50 text-blue-500",
      progressColor: "bg-[#3852b4]",
      icon: <img src={pembeliIcon} alt="Ikon Pembeli" className="w-6 h-6 object-contain" />, 
    },
    {
      title: "TOTAL KANTIN",
      value: totalKantin.toString(), // Angka dinamis!
      iconBg: "bg-orange-50 text-orange-500",
      progressColor: "bg-warm-orange",
      icon: <img src={kantinIcon} alt="Ikon Kantin" className="w-6 h-6 object-contain" />, 
    },
  ];

  return (
    <AdminLayout>
      <section className="flex flex-wrap items-center gap-[42px] px-8 py-7 w-full">
        {summaryCards.map((card) => (
          <StatCard 
            key={card.title} 
            title={card.title}
            value={card.value}
            iconBg={card.iconBg}
            progressColor={card.progressColor}
            icon={card.icon}
          />
        ))}
      </section>
      
      <ActivityTable aktivitas={aktivitas} />
    </AdminLayout>
  );
}