import React from 'react';
import { Link, usePage } from '@inertiajs/react';

const managementSections = [
  {
    heading: "MANAJEMEN KANTIN",
    items: [
      {
        label: "Daftar Kantin",
        // Ikon Toko/Kantin
        icon: (
          <svg className="w-[18px] h-[18px]" fill="currentColor" viewBox="0 0 24 24">
            <path d="M5.223 2.224a1.5 1.5 0 011.054-.424h11.446c.398 0 .78.158 1.054.424l3 3A1.5 1.5 0 0121 6.286V19.5A1.5 1.5 0 0119.5 21h-15A1.5 1.5 0 013 19.5V6.286a1.5 1.5 0 01.223-1.062l3-3zM4.5 7.5v12h15v-12H4.5zm2.25-3l-1.5 1.5h13.5l-1.5-1.5h-10.5zM12 10.5a.75.75 0 00-.75.75v3a.75.75 0 001.5 0v-3a.75.75 0 00-.75-.75z" />
          </svg>
        ),
        href: route('admin.canteens.index'),
        activePath: '/admin/canteens',
      },
    ],
  },
  {
    heading: "MANAJEMEN MAHASISWA",
    items: [
      {
        label: "Daftar Mahasiswa",
        // Ikon Grup Pembeli (3 Orang)
        icon: (
          <svg className="w-[18px] h-[18px]" fill="currentColor" viewBox="0 0 20 20">
            <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z" />
          </svg>
        ),
        href: route('admin.buyers.index'),
        activePath: '/admin/buyers',
      },
      {
        label: "Persetujuan Akun Mahasiswa",
        multiline: true,
        badge: 12, // Badge notifikasi ditambahkan di sini
        // Ikon Persetujuan (Orang & Checklist)
        icon: (
          <svg className="w-[18px] h-[18px]" fill="currentColor" viewBox="0 0 20 20">
            <path d="M8 9a3 3 0 100-6 3 3 0 000 6zM8 11a6 6 0 016 6H2a6 6 0 016-6z" />
            <path fillRule="evenodd" d="M16.707 10.293a1 1 0 010 1.414l-3 3a1 1 0 01-1.414 0l-1.5-1.5a1 1 0 011.414-1.414L13 12.586l2.293-2.293a1 1 0 011.414 0z" clipRule="evenodd" />
          </svg>
        ),
        href: '#',
        activePath: '/admin/approvals',
      },
    ],
  },
];

export default function Sidebar() {
  const { url } = usePage();
  const isDashboardActive = url.startsWith('/admin/dashboard');

  return (
    <aside
      className="flex flex-col w-61 h-screen items-start bg-[#1e2d6b] flex-shrink-0 z-20"
      aria-label="Sidebar admin"
    >
      <div className="flex items-center gap-3 p-6 relative self-stretch w-full flex-[0_0_auto] border-b [border-bottom-style:solid] border-[#ffffff1a]">
        <div className="flex w-9 h-9 items-center justify-center relative bg-[#f08d39] rounded-xl shadow-sm">
          {/* Ikon Sendok Garpu untuk Logo Utama */}
          <svg className="w-5 h-5 text-white" viewBox="0 0 24 24" fill="currentColor">
            <path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z"/>
          </svg>
        </div>
        <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
          <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
            <div className="relative flex items-center h-4 mt-[-1.00px] [font-family:'Inter-Bold',Helvetica] font-bold text-white text-base tracking-[-0.40px] leading-4 whitespace-nowrap">
              Admin Kantin
            </div>
          </div>
          <div className="relative flex items-center h-4 mt-[-0.5px] [font-family:'Inter-Medium',Helvetica] font-medium text-[#5e7ac4] text-xs tracking-[0] leading-4 whitespace-nowrap">
            Management System
          </div>
        </div>
      </div>
      
      <nav
        className="flex flex-col items-start gap-1 px-4 py-6 relative flex-1 self-stretch w-full grow overflow-y-auto"
        aria-label="Navigasi utama admin"
      >
        <Link
          href={route('admin.dashboard')}
          aria-current={isDashboardActive ? "page" : undefined}
          className={`flex items-center gap-3 px-4 py-2.5 relative self-stretch w-full flex-[0_0_auto] rounded-xl text-left transition-colors ${
            isDashboardActive ? 'bg-[#3852b4]' : 'hover:bg-[#ffffff0d]'
          }`}
        >
          <div className={`flex items-center justify-center w-5 h-5 ${isDashboardActive ? 'text-white' : 'text-blue-200 opacity-70'}`}>
            {/* Ikon Speedometer untuk Dashboard */}
            <svg className="w-[18px] h-[18px]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6m0 0l-2.5 2.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div className={`relative flex items-center h-5 [font-family:'Inter-SemiBold',Helvetica] font-semibold text-sm tracking-[0] leading-5 whitespace-nowrap ${isDashboardActive ? 'text-white' : 'text-blue-200'}`}>
            Dashboard
          </div>
        </Link>
        
        {managementSections.map((section) => (
          <div
            key={section.heading}
            className="flex flex-col items-start self-stretch w-full flex-[0_0_auto]"
          >
            <div className="flex flex-col items-start pt-5 pb-2 px-0 relative self-stretch w-full flex-[0_0_auto]">
              <div className="flex flex-col items-start px-4 py-0 relative self-stretch w-full flex-[0_0_auto]">
                <div className="relative flex items-center self-stretch mt-[-1.00px] [font-family:'Inter-SemiBold',Helvetica] font-semibold text-[#5e7ac4] text-xs tracking-[1.20px] leading-4">
                  {section.heading}
                </div>
              </div>
            </div>
            
            {section.items.map((item) => {
              const isActive = item.activePath ? url.startsWith(item.activePath) : false;
              
              return (
                <Link
                  key={item.label}
                  href={item.href}
                  className={`flex items-center gap-3 px-4 py-2.5 relative self-stretch w-full flex-[0_0_auto] rounded-xl text-left transition-colors ${
                    isActive ? 'bg-[#3852b4]' : 'hover:bg-[#ffffff0d]'
                  }`}
                >
                  <div
                    className={`flex items-center justify-center w-5 h-5 ${isActive ? 'text-white' : 'text-blue-200 opacity-70'}`}
                    aria-hidden="true"
                  >
                    {item.icon}
                  </div>
                  
                  {item.multiline ? (
                    <div className="flex items-center justify-between flex-1">
                      <div className={`relative [font-family:'Inter-Medium',Helvetica] font-medium text-sm tracking-[0] leading-5 ${isActive ? 'text-white font-semibold' : 'text-blue-200'}`}>
                        Persetujuan Akun<br />Mahasiswa
                      </div>
                      {/* Render Badge Notifikasi jika ada */}
                      {item.badge && (
                        <div className="flex items-center justify-center px-2 py-0.5 bg-[#f08d39] rounded-full text-white text-xs font-bold">
                          {item.badge}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
                      <div
                        className={`relative flex items-center h-5 mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-sm tracking-[0] leading-5 whitespace-nowrap ${
                          isActive ? 'text-white font-semibold' : 'text-blue-200'
                        }`}
                      >
                        {item.label}
                      </div>
                    </div>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>
      
      <div className="flex flex-col items-start pt-0 pb-6 px-4 relative self-stretch w-full flex-[0_0_auto]">
        <button
          type="button"
          className="flex items-center justify-between gap-3 px-4 py-3 relative self-stretch w-full flex-[0_0_auto] bg-[#ffffff0d] hover:bg-[#ffffff1a] transition-colors rounded-xl border border-solid border-[#ffffff1a] text-left"
          aria-label="Profil Admin Utama, Super Admin"
        >
          <div className="flex items-center gap-3">
            <div
              className="relative w-8 h-8 rounded-full border-2 border-solid border-[#f08d39] bg-[url(/admin-avatar.png)] bg-cover bg-[50%_50%]"
              aria-hidden="true"
            />
            <div className="flex flex-col items-start">
              <div className="relative flex items-center [font-family:'Inter-SemiBold',Helvetica] font-semibold text-white text-xs tracking-[0] leading-4">
                Admin Utama
              </div>
              <div className="relative flex items-center [font-family:'Inter-Regular',Helvetica] font-normal text-[#5e7ac4] text-xs tracking-[0] leading-4 mt-0.5">
                Super Admin
              </div>
            </div>
          </div>
          
          {/* Ikon Logout/Keluar menggantikan vector16 */}
          <div className="text-[#5e7ac4] hover:text-white transition-colors">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
          </div>
        </Link>
      </div>
    </aside>
  );
}