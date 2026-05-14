import React, { useId, useState } from "react";
import { Head, useForm } from "@inertiajs/react"; 
import heroImage from "../../Components/UI/hero-dashboard.svg";
import forkIcon from "../../Components/UI/fork.svg";
import mailIcon from "../../Components/UI/mail.svg";
import lockIcon from "../../Components/UI/lock.svg";

const featureHeadingLines = ["Kelola Kantin dengan", "Mudah & Terpusat"];
const featureDescriptionLines = [
  "Sistem manajemen terintegrasi untuk efisiensi",
  "operasional dan analisis data kantin Anda.",
];

export default function Login() {
  const emailId = useId();
  const passwordId = useId();
  const rememberMeId = useId();

  const { data, setData, post, processing, errors, reset } = useForm({
    email: "",
    password: "",
    remember: false, 
  });

  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = (event) => {
    event.preventDefault();
    post(route("login"), {
      onFinish: () => reset("password"),
    });
  };

  return (
    <main className="flex min-h-screen items-start relative bg-[linear-gradient(0deg,rgba(244,246,251,1)_0%,rgba(244,246,251,1)_100%),linear-gradient(0deg,rgba(255,255,255,1)_0%,rgba(255,255,255,1)_100%)]">
      <Head title="Admin Login" />

      <section
        aria-label="Informasi sistem"
        className="flex flex-col items-center justify-center p-12 relative flex-1 self-stretch grow bg-[#1e2d6b]"
      >
        <div
          aria-hidden="true"
          className="absolute w-full h-full top-0 left-0 opacity-20 overflow-hidden pointer-events-none"
        >
        </div>
        <div className="inline-flex flex-col min-w-[448px] max-w-md items-start gap-4 relative flex-[0_0_auto]">
          <div className="relative self-stretch w-full max-h-80 h-80 bg-[#ffffff01] rounded-2xl overflow-hidden shadow-[0px_25px_50px_-12px_#00000040]">
            <img 
              src={heroImage} 
              alt="Dashboard Analytics Illustration"
              className="w-full h-full object-cover object-center relative z-10"
            />
            <div className="absolute inset-0 bg-[#1e2d6b]/10 mix-blend-multiply pointer-events-none z-20" />
          </div>
          <div className="flex flex-col items-center pt-4 pb-0 px-0 relative self-stretch w-full flex-[0_0_auto]">
            <h1 className="relative w-[355px] h-20 mt-[-1.00px] [font-family:'Inter-Bold',Helvetica] font-bold text-white text-4xl text-center tracking-[-0.90px] leading-10">
              {featureHeadingLines.map((line, index) => (
                <React.Fragment key={line}>
                  {line}
                  {index < featureHeadingLines.length - 1 ? <br /> : null}
                </React.Fragment>
              ))}
            </h1>
          </div>
          <div className="flex flex-col items-center relative self-stretch w-full flex-[0_0_auto]">
            <p className="relative w-[390.2px] h-14 mt-[-1.00px] [font-family:'Inter-Regular',Helvetica] font-normal text-blue-200 text-lg text-center tracking-[0] leading-7">
              {featureDescriptionLines.map((line, index) => (
                <React.Fragment key={line}>
                  {line}
                  {index < featureDescriptionLines.length - 1 ? <br /> : null}
                </React.Fragment>
              ))}
            </p>
          </div>
        </div>
      </section>

      <section className="flex-col items-center justify-center p-12 flex-1 self-stretch grow bg-[#f4f6fb] flex relative">
        <form
          onSubmit={handleSubmit}
          className="flex-col max-w-[440px] w-[440px] items-start gap-8 pt-10 pb-14 px-10 flex-[0_0_auto] bg-white rounded-2xl shadow-[0px_4px_40px_#0000000a] flex relative"
        >
          <div className="flex flex-col items-start gap-2 relative self-stretch w-full flex-[0_0_auto]">
            <div className="flex items-center justify-center gap-3 relative self-stretch w-full flex-[0_0_auto]">
              
              {/* BAGIAN LOGO FORK.SVG */}
              <div className="w-10 h-10 items-center justify-center bg-[#3852b4] rounded-[10px] flex relative">
                <div className="absolute top-[calc(50.00%_-_20px)] left-[calc(50.00%_-_20px)] w-10 h-10 bg-[#ffffff01] rounded-[10px] shadow-[0px_4px_6px_-4px_#3852b44c,0px_10px_15px_-3px_#3852b44c]" />
                <div className="inline-flex flex-col items-center relative flex-[0_0_auto]">
                  {/* Memanggil gambar sendok garpu */}
                  <img src={forkIcon} alt="Logo" className="w-5 h-5 object-contain" />
                </div>
              </div>
              
              <div className="inline-flex flex-col items-center relative flex-[0_0_auto]">
                <div className="relative flex items-center justify-center w-[232px] h-8 mt-[-1.00px] [font-family:'Inter-Bold',Helvetica] font-bold text-gray-900 text-2xl text-center tracking-[-0.60px] leading-8 whitespace-nowrap">
                  Admin Polycanteen
                </div>
              </div>
            </div>
            <div className="flex flex-col items-center pt-4 pb-0 px-0 relative self-stretch w-full flex-[0_0_auto]">
              <h2 className="relative flex items-center justify-center w-[243.64px] h-8 mt-[-1.00px] [font-family:'Inter-SemiBold',Helvetica] font-semibold text-gray-800 text-2xl text-center tracking-[0] leading-8 whitespace-nowrap">
                Masuk ke Dashboard
              </h2>
            </div>
            <div className="flex flex-col items-center relative self-stretch w-full flex-[0_0_auto]">
              <p className="relative flex items-center justify-center w-[353.97px] h-5 mt-[-1.00px] [font-family:'Inter-Regular',Helvetica] font-normal text-gray-500 text-sm text-center tracking-[0] leading-5 whitespace-nowrap">
                Silakan masukkan kredensial Anda untuk melanjutkan
              </p>
            </div>
          </div>

          <div className="flex flex-col items-start gap-5 relative self-stretch w-full flex-[0_0_auto]">
            {/* Input Email */}
            <div className="flex flex-col items-start gap-1.5 relative self-stretch w-full flex-[0_0_auto]">
              <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
                
                <label
                  htmlFor={emailId}
                  className="relative flex items-center self-stretch mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-gray-700 text-sm tracking-[0] leading-5"
                >
                  Email
                </label>
              </div>
              <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
                <div className="flex flex-col items-start pl-10 pr-4 py-3.5 relative self-stretch w-full flex-[0_0_auto] bg-[#f9fafb80] rounded-xl overflow-hidden border border-solid shadow-[0px_1px_2px_#0000000d]">
                  <input
                    id={emailId}
                    name="email"
                    autoComplete="email"
                    inputMode="email"
                    aria-label="Email"
                    className="relative self-stretch w-full border-[none] [background:none] h-5 mt-[-1.00px] [font-family:'Inter-Regular',Helvetica] font-normal text-gray-700 placeholder:text-gray-400 text-base tracking-[0] leading-[normal] p-0 focus:ring-0"
                    placeholder="admin@kantin.com"
                    type="email"
                    value={data.email}
                    onChange={(e) => setData("email", e.target.value)} 
                  />
                </div>
                <div aria-hidden="true" className="inline-flex h-full items-center pl-3.5 pr-0 py-0 absolute top-0 left-0">
                  <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
                    <div className="inline-flex flex-col items-center relative flex-[0_0_auto]">
                      {/* Memanggil gambar sendok garpu */}
                      <img src={mailIcon} alt="Logo" className="w-5 h-5 object-contain" />
                    </div>
                  </div>
                </div>
              </div>
              {errors.email && <span className="text-red-500 text-xs mt-1">{errors.email}</span>}
            </div>

            {/* Input Password */}
            <div className="flex flex-col items-start gap-1.5 relative self-stretch w-full flex-[0_0_auto]">
              <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
                <label
                  htmlFor={passwordId}
                  className="relative flex items-center self-stretch mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-gray-700 text-sm tracking-[0] leading-5"
                >
                  Password
                </label>
              </div>
              <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
                <div className="flex flex-col items-start px-10 pr-14 py-3.5 self-stretch w-full flex-[0_0_auto] bg-[#f9fafb80] rounded-xl overflow-hidden border shadow-[0px_1px_2px_#0000000d] relative border-solid">
                  <input
                    id={passwordId}
                    name="password"
                    autoComplete="current-password"
                    aria-label="Password"
                    className="relative self-stretch w-full border-[none] [background:none] h-5 mt-[-1.00px] [font-family:'Inter-Regular',Helvetica] font-normal text-gray-700 placeholder:text-gray-400 text-base tracking-[0] leading-[normal] p-0 focus:ring-0"
                    placeholder="••••••••"
                    type={showPassword ? "text" : "password"}
                    value={data.password} 
                    onChange={(e) => setData("password", e.target.value)} 
                  />
                </div>
                <div aria-hidden="true" className="inline-flex h-full items-center pl-3.5 pr-0 py-0 absolute top-0 left-0">
                  <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
                    <div className="inline-flex flex-col items-center relative flex-[0_0_auto]">
                      <img src={lockIcon} alt="Logo" className="w-5 h-5 object-contain" />
                    </div>
                  </div>
                </div>
                <button
                  type="button"
                  aria-label={showPassword ? "Sembunyikan password" : "Tampilkan password"}
                  aria-pressed={showPassword}
                  onClick={() => setShowPassword((current) => !current)}
                  className="all-[unset] box-border inline-flex h-full items-center justify-center w-12 absolute top-0 right-0 cursor-pointer"
                >
                  <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                    className="text-gray-500"
                    aria-hidden="true"
                  >
                    {showPassword ? (
                      <path d="M12 5C7 5 2.73 8.11 1 12c1.73 3.89 6 7 11 7s9.27-3.11 11-7c-1.73-3.89-6-7-11-7Zm0 12a5 5 0 1 1 0-10 5 5 0 0 1 0 10Zm0-8a3 3 0 1 0 0 6 3 3 0 0 0 0-6Z" fill="currentColor" />
                    ) : (
                      <>
                        <path d="M12 5c-3.26 0-6.28 1.64-8.4 4.2l1.46 1.46C6.75 8.65 9.24 7.5 12 7.5c4.64 0 8.24 3.14 9.27 7.5-.46 1.64-1.28 3.13-2.34 4.32l1.42 1.42C21.17 18.24 22 15.24 22 12c-1.73-3.89-6-7-11-7Zm-9.19-.19L2.81 1.81 22.19 21.19l-1.42 1.42L14.83 16.7C13.53 17.27 12.05 17.5 10.5 17.5 5.86 17.5 2.26 14.36 1.23 10.8c.5-1.78 1.45-3.39 2.73-4.62L2.81 4.81ZM12 15a3 3 0 0 0 2.83-4H6.17a3 3 0 0 0 5.83 4Zm0-6a3 3 0 0 0-2.83 4h5.66A3 3 0 0 0 12 9Z" fill="currentColor" />
                      </>
                    )}
                  </svg>
                </button>
              </div>
              {errors.password && <span className="text-red-500 text-xs mt-1">{errors.password}</span>}
            </div>

            {/* Checkbox Remember Me */}
            <div className="flex items-center justify-around gap-[130.31px] pr-[1.14e-13px] pl-0 pt-1 pb-0 relative self-stretch w-full flex-[0_0_auto]">
              <label
                htmlFor={rememberMeId}
                className="inline-flex items-center relative flex-[0_0_auto] cursor-pointer"
              >
                <input
                  id={rememberMeId}
                  name="remember"
                  type="checkbox"
                  checked={data.remember} 
                  onChange={(e) => setData("remember", e.target.checked)} 
                  className="peer sr-only"
                />
                <div className="w-4 h-4 bg-white rounded-[2.5px] border-[#767676] relative border border-solid peer-checked:bg-[#3852b4] peer-checked:border-[#3852b4] flex items-center justify-center transition-colors">
                  <span className="text-[10px] leading-none text-white opacity-0 peer-checked:opacity-100">
                    ✓
                  </span>
                </div>
                <div className="inline-flex flex-col items-start pl-2 pr-0 py-0 relative flex-[0_0_auto]">
                  <div className="relative flex items-center w-[96.18px] h-5 mt-[-1.00px] [font-family:'Inter-Regular',Helvetica] font-normal text-gray-600 text-sm tracking-[0] leading-5 whitespace-nowrap">
                    Remember me
                  </div>
                </div>
              </label>
            </div>

            {/* Tombol Submit */}
            <button
              type="submit"
              disabled={processing}
              className={`all-[unset] box-border flex items-start justify-center px-4 py-3.5 relative self-stretch w-full flex-[0_0_auto] bg-[#3852b4] rounded-xl border border-solid border-transparent cursor-pointer hover:bg-[#2c4190] transition-colors ${processing ? 'opacity-75 cursor-wait' : ''}`}
            >
              <div className="absolute w-full h-full top-0 left-0 bg-[#ffffff01] rounded-xl shadow-[0px_2px_4px_-2px_#0000001a,0px_4px_6px_-1px_#0000001a]" />
              <div className="relative flex items-center justify-center w-[45.33px] h-5 mt-[-1.00px] [font-family:'Inter-SemiBold',Helvetica] font-semibold text-white text-sm text-center tracking-[0] leading-5 whitespace-nowrap">
                {processing ? "Loading..." : "Masuk"}
              </div>
            </button>
          </div>
        </form>
        
        <footer className="inline-flex flex-col items-start pt-8 pb-0 px-0 relative flex-[0_0_auto]">
          <div className="inline-flex flex-col items-center relative flex-[0_0_auto]">
            <p className="relative flex items-center justify-center w-[281.61px] h-5 mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-gray-500 text-sm text-center tracking-[0] leading-5 whitespace-nowrap">
              © 2026 Sistem Kantin. All rights reserved.
            </p>
          </div>
        </footer>
      </section>
    </main>
  );
}