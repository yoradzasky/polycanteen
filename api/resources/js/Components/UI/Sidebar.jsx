import React, { useState } from 'react';
import { Link, usePage, useForm } from '@inertiajs/react';
import Modal from '@/Components/Modal';
import InputLabel from '@/Components/InputLabel';
import TextInput from '@/Components/TextInput';
import InputError from '@/Components/InputError';
import PrimaryButton from '@/Components/PrimaryButton';
import logo from './logo.jpg';
export default function Sidebar() {
  const { url, props } = usePage();
  const isDashboardActive = url.startsWith('/admin/dashboard');
  const approvalCount = props.notifications?.pendingApprovalsCount || 0;

  const [showMenu, setShowMenu] = useState(false);
  const [confirmingPasswordUpdate, setConfirmingPasswordUpdate] = useState(false);

  const { data, setData, errors, put, reset, processing, clearErrors, recentlySuccessful } = useForm({
    current_password: '',
    password: '',
    password_confirmation: '',
  });

  const updatePassword = (e) => {
    e.preventDefault();
    put(route('admin.password.update'), {
      preserveScroll: true,
      onSuccess: () => {
        reset();
      },
      onError: () => {
      }
    });
  };

  const closeModal = () => {
    setConfirmingPasswordUpdate(false);
    reset();
    clearErrors();
  };

  const managementSections = [
    {
      heading: "MANAJEMEN KANTIN",
      items: [
        {
          label: "Daftar Kantin",
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
          badge: approvalCount,
          icon: (
            <svg className="w-[18px] h-[18px]" fill="currentColor" viewBox="0 0 20 20">
              <path d="M8 9a3 3 0 100-6 3 3 0 000 6zM8 11a6 6 0 016 6H2a6 6 0 016-6z" />
              <path fillRule="evenodd" d="M16.707 10.293a1 1 0 010 1.414l-3 3a1 1 0 01-1.414 0l-1.5-1.5a1 1 0 011.414-1.414L13 12.586l2.293-2.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
          ),
          href: route('admin.approvals.index'),
          activePath: '/admin/approvals',
        },
      ],
    },
  ];

  return (
    <aside
      className="flex flex-col w-61 h-screen items-start bg-[#1e2d6b] flex-shrink-0 z-20"
      aria-label="Sidebar admin"
    >
      <div className="flex items-center gap-3 p-6 relative self-stretch w-full flex-[0_0_auto] border-b [border-bottom-style:solid] border-[#ffffff1a]">
        <div className="flex w-10 h-10 items-center justify-center relative rounded-xl shadow-sm overflow-hidden bg-white">
          <img src={logo} alt="Logo Kantin" className="w-full h-full object-cover" />
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
          className={`flex items-center gap-3 px-4 py-2.5 relative self-stretch w-full flex-[0_0_auto] rounded-xl text-left transition-colors ${isDashboardActive ? 'bg-[#3852b4]' : 'hover:bg-[#ffffff0d]'
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
                  className={`flex items-center gap-3 px-4 py-2.5 relative self-stretch w-full flex-[0_0_auto] rounded-xl text-left transition-colors ${isActive ? 'bg-[#3852b4]' : 'hover:bg-[#ffffff0d]'
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
                        className={`relative flex items-center h-5 mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-sm tracking-[0] leading-5 whitespace-nowrap ${isActive ? 'text-white font-semibold' : 'text-blue-200'
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
        {showMenu && (
          <div className="absolute bottom-[80px] left-4 w-[calc(100%-2rem)] bg-[#2a3c86] rounded-xl shadow-lg py-2 z-50 border border-[#ffffff1a]">
             <button 
                className="w-full text-left px-4 py-2 text-sm text-white hover:bg-[#3852b4] transition-colors"
                onClick={() => { setShowMenu(false); setConfirmingPasswordUpdate(true); }}
             >
                Ganti Password
             </button>
             <Link 
                href={route('logout')} 
                method="post" 
                as="button"
                className="w-full text-left px-4 py-2 text-sm text-[#ff6b6b] hover:bg-[#3852b4] transition-colors"
             >
                Logout
             </Link>
          </div>
        )}
        <button
          type="button"
          onClick={() => setShowMenu(!showMenu)}
          className="flex items-center justify-between gap-3 px-4 py-3 relative self-stretch w-full flex-[0_0_auto] bg-[#ffffff0d] hover:bg-[#ffffff1a] transition-colors rounded-xl border border-solid border-[#ffffff1a] text-left"
          aria-label="Profil Admin"
        >
          <div className="flex items-center gap-3">
            <div
              className="relative w-8 h-8 rounded-full border-2 border-solid border-[#f08d39] bg-[url(/admin-avatar.png)] bg-cover bg-[50%_50%]"
              aria-hidden="true"
            />
            <div className="flex flex-col items-start">
              <div className="relative flex items-center [font-family:'Inter-SemiBold',Helvetica] font-semibold text-white text-xs tracking-[0] leading-4">
                Admin
              </div>
              <div className="relative flex items-center [font-family:'Inter-Regular',Helvetica] font-normal text-[#5e7ac4] text-xs tracking-[0] leading-4 mt-0.5">
                Admin
              </div>
            </div>
          </div>

          <div className="text-[#5e7ac4] hover:text-white transition-colors">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 15l7-7 7 7" />
            </svg>
          </div>
        </button>
      </div>

      <Modal show={confirmingPasswordUpdate} onClose={closeModal}>
        <div className="p-8">
          <div className="flex items-center gap-4 mb-8">
            <div className="w-12 h-12 rounded-2xl bg-[#f08d39] flex items-center justify-center text-white shadow-md">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
            </div>
            <div>
              <h2 className="[font-family:'Inter-Bold',Helvetica] font-bold text-gray-900 text-xl tracking-tight">
                Ganti Password Admin
              </h2>
              <p className="[font-family:'Inter-Medium',Helvetica] text-sm text-gray-500 mt-1">
                Pastikan akun Anda menggunakan password yang aman.
              </p>
            </div>
          </div>

          {recentlySuccessful && (
             <div className="mb-6 px-4 py-3 bg-green-50 border border-green-200 text-green-700 rounded-xl flex items-center gap-3">
                 <svg className="w-5 h-5 text-green-500 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"></path></svg>
                 <span className="[font-family:'Inter-SemiBold',Helvetica] text-sm tracking-tight">Password berhasil diperbarui!</span>
             </div>
          )}

          <form onSubmit={updatePassword} className="space-y-5">
            <div>
              <InputLabel htmlFor="current_password" value="Password Saat Ini" className="text-gray-700 font-semibold mb-1.5" />
              <TextInput
                id="current_password"
                type="password"
                name="current_password"
                value={data.current_password}
                onChange={(e) => setData('current_password', e.target.value)}
                className="mt-1 block w-full rounded-xl border-gray-300 focus:border-[#3852b4] focus:ring focus:ring-[#3852b4] focus:ring-opacity-20 shadow-sm px-4 py-2.5 transition-shadow"
                autoComplete="current-password"
                placeholder="Masukkan password saat ini"
              />
              <InputError message={errors.current_password} className="mt-2 text-red-500 text-sm" />
            </div>

            <div>
              <InputLabel htmlFor="password" value="Password Baru" className="text-gray-700 font-semibold mb-1.5" />
              <TextInput
                id="password"
                type="password"
                name="password"
                value={data.password}
                onChange={(e) => setData('password', e.target.value)}
                className="mt-1 block w-full rounded-xl border-gray-300 focus:border-[#3852b4] focus:ring focus:ring-[#3852b4] focus:ring-opacity-20 shadow-sm px-4 py-2.5 transition-shadow"
                autoComplete="new-password"
                placeholder="Minimal 8 karakter"
              />
              <InputError message={errors.password} className="mt-2 text-red-500 text-sm" />
            </div>

            <div>
              <InputLabel htmlFor="password_confirmation" value="Konfirmasi Password Baru" className="text-gray-700 font-semibold mb-1.5" />
              <TextInput
                id="password_confirmation"
                type="password"
                name="password_confirmation"
                value={data.password_confirmation}
                onChange={(e) => setData('password_confirmation', e.target.value)}
                className="mt-1 block w-full rounded-xl border-gray-300 focus:border-[#3852b4] focus:ring focus:ring-[#3852b4] focus:ring-opacity-20 shadow-sm px-4 py-2.5 transition-shadow"
                autoComplete="new-password"
                placeholder="Ulangi password baru"
              />
              <InputError message={errors.password_confirmation} className="mt-2 text-red-500 text-sm" />
            </div>

            <div className="pt-4 flex justify-end gap-3">
              <button
                  type="button"
                  onClick={closeModal}
                  className="inline-flex items-center px-5 py-2.5 bg-white border border-gray-300 rounded-xl font-semibold text-sm text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-[#3852b4] focus:ring-offset-1 transition ease-in-out duration-150 shadow-sm"
              >
                Batal
              </button>

              <button
                  type="submit"
                  disabled={processing}
                  className={`inline-flex items-center px-5 py-2.5 bg-[#3852b4] border border-transparent rounded-xl font-semibold text-sm text-white hover:bg-[#2a3c86] focus:outline-none focus:ring-2 focus:ring-[#3852b4] focus:ring-offset-1 transition ease-in-out duration-150 shadow-sm ${processing && 'opacity-70 cursor-not-allowed'}`}
              >
                Simpan Password
              </button>
            </div>
          </form>
        </div>
      </Modal>
    </aside>
  );
}