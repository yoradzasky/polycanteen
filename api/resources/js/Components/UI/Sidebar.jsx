import vector13 from "./vector-13.svg";
import vector16 from "./vector-16.svg";

const managementSections = [
  {
    heading: "MANAJEMEN KANTIN",
    items: [
      {
        label: "Daftar Kantin",
        icon: (
          <div className="relative w-[15.75px] h-3.5">
            <img
              className="absolute w-[97.23%] h-full top-0 left-[2.77%]"
              alt=""
              src={vector13}
              aria-hidden="true"
            />
          </div>
        ),
      },
    ],
  },
  {
    heading: "MANAJEMEN PEMBELI",
    items: [
      {
        label: "Daftar Pembeli",
        icon: (
          <div className="relative w-[17.5px] h-3.5 mr-[-1.50px] bg-[url(/vector-14.svg)] bg-[100%_100%]" />
        ),
      },
      {
        label: "Persetujuan Akun Pembeli",
        multiline: true,
        icon: (
          <div className="relative w-[17.28px] h-3.5 mr-[-1.28px] bg-[url(/vector-15.svg)] bg-[100%_100%]" />
        ),
      },
    ],
  },
];

export default function Sidebar() {
  return (
    <aside
      className="flex flex-col w-60 h-[890px] items-start absolute top-0 left-0 bg-[#1e2d6b]"
      aria-label="Sidebar admin"
    >
      <div className="flex items-center gap-3 p-6 relative self-stretch w-full flex-[0_0_auto] border-b [border-bottom-style:solid] border-[#ffffff1a]">
        <div className="flex w-9 h-9 items-center justify-center relative bg-warm-orange rounded-xl">
          <div
            className="absolute top-[calc(50.00%_-_18px)] left-0 w-9 h-9 bg-[#ffffff01] rounded-xl shadow-[0px_4px_6px_-4px_#0000001a,0px_10px_15px_-3px_#0000001a]"
            aria-hidden="true"
          />
          <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
            <div
              className="relative w-[12.25px] h-3.5 bg-[url(/vector-11.svg)] bg-[100%_100%]"
              aria-hidden="true"
            />
          </div>
        </div>
        <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
          <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
            <div className="relative flex items-center w-[101.15px] h-4 mt-[-1.00px] [font-family:'Inter-Bold',Helvetica] font-bold text-white text-base tracking-[-0.40px] leading-4 whitespace-nowrap">
              Admin Kantin
            </div>
          </div>
          <div className="relative flex items-center w-[122.18px] h-4 mt-[-0.5px] [font-family:'Inter-Medium',Helvetica] font-medium text-[#5e7ac4] text-xs tracking-[0] leading-4 whitespace-nowrap">
            Management System
          </div>
        </div>
      </div>
      <nav
        className="flex flex-col items-start gap-1 px-4 py-6 relative flex-1 self-stretch w-full grow"
        aria-label="Navigasi utama admin"
      >
        <button
          type="button"
          aria-current="page"
          className="flex items-center gap-3 px-4 py-2.5 relative self-stretch w-full flex-[0_0_auto] bg-[#3852b4] rounded-xl text-left"
        >
          <div
            className="absolute w-full h-full top-0 left-0 bg-[#ffffff01] rounded-xl shadow-[0px_4px_6px_-4px_#3852b44c,0px_10px_15px_-3px_#3852b44c]"
            aria-hidden="true"
          />
          <div className="flex flex-col w-4 items-start relative">
            <div
              className="relative w-4 h-4 bg-[url(/vector-12.svg)] bg-[100%_100%]"
              aria-hidden="true"
            />
          </div>
          <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
            <div className="relative flex items-center w-[74.11px] h-5 mt-[-1.00px] [font-family:'Inter-SemiBold',Helvetica] font-semibold text-white text-sm tracking-[0] leading-5 whitespace-nowrap">
              Dashboard
            </div>
          </div>
        </button>
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
            {section.items.map((item) => (
              <button
                key={item.label}
                type="button"
                className="flex items-center gap-3 px-4 py-2.5 relative self-stretch w-full flex-[0_0_auto] rounded-xl text-left"
              >
                <div
                  className="flex flex-col w-4 items-start relative"
                  aria-hidden="true"
                >
                  {item.icon}
                </div>
                {item.multiline ? (
                  <div className="inline-flex flex-col items-start pl-0 pr-[29.86px] py-0 relative flex-[0_0_auto]">
                    <div className="relative w-[118.14px] h-10 mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-blue-200 text-sm tracking-[0] leading-5">
                      Persetujuan Akun
                      <br />
                      Pembeli
                    </div>
                  </div>
                ) : (
                  <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
                    <div
                      className={`relative flex items-center h-5 mt-[-1.00px] [font-family:'Inter-Medium',Helvetica] font-medium text-blue-200 text-sm tracking-[0] leading-5 whitespace-nowrap ${
                        item.label === "Daftar Kantin"
                          ? "w-[89.13px]"
                          : "w-[99.15px]"
                      }`}
                    >
                      {item.label}
                    </div>
                  </div>
                )}
              </button>
            ))}
          </div>
        ))}
      </nav>
      <div className="flex flex-col items-start pt-0 pb-6 px-4 relative self-stretch w-full flex-[0_0_auto]">
        <button
          type="button"
          className="flex items-center gap-3 px-4 py-3 relative self-stretch w-full flex-[0_0_auto] bg-[#ffffff0d] rounded-xl border border-solid border-[#ffffff1a] text-left"
          aria-label="Profil Admin Utama, Super Admin"
        >
          <div
            className="relative max-w-52 w-8 h-8 rounded-full border-2 border-solid border-[#f08d39] bg-[url(/admin-avatar.png)] bg-cover bg-[50%_50%]"
            aria-hidden="true"
          />
          <div className="flex flex-col items-start relative flex-1 grow">
            <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
              <div className="relative flex items-center self-stretch mt-[-1.00px] [font-family:'Inter-SemiBold',Helvetica] font-semibold text-white text-xs tracking-[0] leading-4">
                Admin Utama
              </div>
            </div>
            <div className="flex flex-col items-start relative self-stretch w-full flex-[0_0_auto]">
              <div className="relative flex items-center self-stretch mt-[-1.00px] [font-family:'Inter-Regular',Helvetica] font-normal text-[#5e7ac4] text-xs tracking-[0] leading-4">
                Super Admin
              </div>
            </div>
          </div>
          <div className="inline-flex flex-col items-start relative flex-[0_0_auto]">
            <div className="relative w-3 h-3">
              <img
                className="absolute w-full h-[93.75%] top-[6.25%] left-0"
                alt=""
                src={vector16}
                aria-hidden="true"
              />
            </div>
          </div>
        </button>
      </div>
    </aside>
  );
};
