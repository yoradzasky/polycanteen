import AdminLayout from '@/Layouts/AdminLayout';
import StatCard from '@/Components/UI/StatCard';

export default function Index() {
    // Data untuk 3 kartu (diambil dari kode Anima kamu)
    const summaryCards = [
      {
        title: "TOTAL TRANSAKSI",
        value: "Rp 48,2 Jt",
        iconBg: "bg-emerald-50 text-emerald-500",
        progressColor: "bg-emerald-400",
        icon: "💰", // Pengganti image.svg
      },
      {
        title: "TOTAL PEMBELI",
        value: "1,284",
        iconBg: "bg-blue-50 text-blue-500",
        progressColor: "bg-[#3852b4]",
        icon: "👥", // Pengganti vector-2.svg
      },
      {
        title: "TOTAL KANTIN",
        value: "16",
        iconBg: "bg-orange-50 text-orange-500",
        progressColor: "bg-warm-orange",
        icon: "🏪", // Pengganti vector-3.svg
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
        </AdminLayout>
    );
}