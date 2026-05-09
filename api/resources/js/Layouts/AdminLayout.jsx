import Sidebar from '@/Components/UI/Sidebar';
import TopNavbar from '@/Components/UI/TopNavbar';

export default function AdminLayout({ children }) {
    return (
        <div className="flex h-screen bg-[#f4f6fb] overflow-hidden">
            {/* Sidebar di Kiri */}
            <Sidebar />

            {/* Konten Utama di Kanan */}
            <div className="flex-1 flex flex-col h-screen overflow-hidden">
                <TopNavbar />
                
                {/* Area ini yang akan berubah-ubah sesuai halaman */}
                <main className="flex-1 overflow-x-hidden overflow-y-auto">
                    {children}
                </main>
            </div>
        </div>
    );
}