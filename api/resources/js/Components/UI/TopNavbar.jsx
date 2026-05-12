import { useId, useState } from "react";

export default function TopNavbar({ title, description, rightContent }) {
  const [searchValue, setSearchValue] = useState("");
  const searchInputId = useId();

  return (
    <header className="flex items-center justify-between px-8 py-4 relative self-stretch w-full flex-[0_0_auto] z-[1] bg-white border-b border-gray-100 shadow-[0px_2px_12px_#3852b40f]">
      <div className="inline-flex flex-col items-start gap-0.5 relative flex-[0_0_auto]">
        <h1 className="[font-family:'Inter-Bold',Helvetica] font-bold text-gray-900 text-xl tracking-[-0.50px] leading-7">
          {title || "Dashboard"}
        </h1>
        <p className="[font-family:'Inter-Medium',Helvetica] font-medium text-gray-400 text-xs leading-4">
          {description || "Selamat datang kembali, Admin Utama 👋"}
        </p>
      </div>
      
      {/* Search Bar or Action Buttons */}
      <div className="inline-flex items-center gap-4 relative flex-[0_0_auto]">
        {rightContent !== undefined ? rightContent : (
          <form role="search" className="inline-flex items-center gap-2 px-4 py-2.5 bg-[#f4f6fb] rounded-xl border border-gray-100" onSubmit={(e) => e.preventDefault()}>
            <label htmlFor={searchInputId} className="sr-only">Cari</label>
            <svg className="w-3.5 h-3.5 text-gray-400" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12.25 12.25L9.7125 9.7125M11.0833 6.41667C11.0833 8.994 8.994 11.0833 6.41667 11.0833C3.83934 11.0833 1.75 8.994 1.75 6.41667C1.75 3.83934 3.83934 1.75 6.41667 1.75C8.994 1.75 11.0833 3.83934 11.0833 6.41667Z" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            <input
              id={searchInputId}
              type="search"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              placeholder="Cari..."
              className="bg-transparent outline-none border-0 p-0 text-sm placeholder:text-gray-400 w-40 focus:ring-0"
            />
          </form>
        )}
      </div>
    </header>
  );
}