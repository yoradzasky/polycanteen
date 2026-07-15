export default function StatCard({ title, value, iconBg, progressColor, icon }) {
  return (
    <article className="relative w-[350px] h-[140px] bg-white rounded-2xl shadow-[0px_2px_16px_#3852b414] p-5">
      <div className="flex items-start justify-between">
        <div className="flex flex-col gap-1">
          <h3 className="font-semibold text-gray-400 text-xs tracking-[0.60px] uppercase">
            {title}
          </h3>
          <p className="font-bold text-gray-900 text-2xl">
            {value}
          </p>
        </div>
        <div className={`flex w-11 h-11 items-center justify-center ${iconBg} rounded-xl text-2xl`}>
            {/* Kita pakai text biasa/emoji/heroicon di sini menggantikan SVG error */}
            {icon} 
        </div>
      </div>
      <div className="absolute w-[calc(100%-40px)] bottom-5 h-1.5 bg-gray-100 rounded-full">
        <div className={`h-1.5 w-full ${progressColor} rounded-full`} />
      </div>
    </article>
  );
}