import { useId, useState } from "react";

export default function TopNavbar({ title, description, rightContent, leftContent }) {
  const [searchValue, setSearchValue] = useState("");
  const searchInputId = useId();

  return (
    <header className="flex items-center justify-between px-8 h-[76px] relative self-stretch w-full flex-[0_0_auto] z-[1] bg-white border-b border-gray-100 shadow-[0px_2px_12px_#3852b40f]">

      {/* Sisi Kiri: Tombol Kembali (jika ada) + Judul & Deskripsi */}
      <div className="flex items-center gap-4">
        {leftContent}

        <div className="inline-flex flex-col items-start gap-0.5 relative flex-[0_0_auto]">
          <h1 className="[font-family:'Inter-Bold',Helvetica] font-bold text-gray-900 text-xl tracking-[-0.50px] leading-7">
            {title || "Dashboard"}
          </h1>
          <div className="[font-family:'Inter-Medium',Helvetica] font-medium text-gray-400 text-xs leading-4">
            {description || "Selamat datang kembali, Admin"}
          </div>
        </div>
      </div>

      {/* Sisi Kanan: Search Bar or Action Buttons */}
      <div className="inline-flex items-center gap-4 relative flex-[0_0_auto]">
        {rightContent ? rightContent : null}

      </div>
    </header>
  );
}