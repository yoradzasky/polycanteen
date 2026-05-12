/**
 * MapPickerModal.jsx
 *
 * Komponen modal reusable untuk memilih koordinat lokasi kantin
 * menggunakan peta interaktif Leaflet.js + OpenStreetMap.
 *
 * DEPENDENCY:
 *   npm install leaflet react-leaflet
 *
 * Tambahkan import CSS Leaflet di resources/js/app.jsx atau resources/css/app.css:
 *   import 'leaflet/dist/leaflet.css';
 */

import { useState, useEffect, useRef, useCallback } from 'react';
import { MapContainer, TileLayer, Marker, Tooltip, useMapEvents, useMap } from 'react-leaflet';
import L from 'leaflet';

// Fix icon Leaflet default yang sering hilang di React
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

// Custom icon biru navy (sesuai gambar)
const customIcon = new L.Icon({
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    shadowSize: [41, 41],
});

const DEFAULT_LAT = -7.05287;   // Koordinat default: Politeknik Negeri Semarang
const DEFAULT_LNG = 110.43476;

// Sub-komponen untuk handle klik peta
function MapClickHandler({ onMapClick }) {
    useMapEvents({
        click(e) {
            onMapClick(e.latlng.lat, e.latlng.lng);
        },
    });
    return null;
}

// Sub-komponen untuk sync posisi marker dari luar (search / lokasi saya)
function MapCenterSync({ position }) {
    const map = useMap();
    useEffect(() => {
        map.setView([position.lat, position.lng], map.getZoom());
    }, [position]);
    return null;
}

/**
 * @param {boolean}  isOpen        - Tampilkan atau sembunyikan modal
 * @param {function} onClose       - Callback saat modal ditutup (Batal / klik ×)
 * @param {function} onConfirm     - Callback saat "Konfirmasi Lokasi" diklik
 *                                   Dipanggil dengan: onConfirm({ lat, lng, alamat })
 * @param {number}   initialLat    - Latitude awal (opsional, untuk mode Edit)
 * @param {number}   initialLng    - Longitude awal (opsional, untuk mode Edit)
 */
export default function MapPickerModal({ isOpen, onClose, onConfirm, initialLat, initialLng }) {
    const [position, setPosition] = useState({
        lat: initialLat ?? DEFAULT_LAT,
        lng: initialLng ?? DEFAULT_LNG,
    });
    const [alamat, setAlamat] = useState('Memuat alamat...');
    const [searchQuery, setSearchQuery] = useState('');
    const [searchResults, setSearchResults] = useState([]);
    const [isSearching, setIsSearching] = useState(false);
    const [loadingAlamat, setLoadingAlamat] = useState(false);

    const searchTimeoutRef = useRef(null);

    // Reset state saat modal dibuka dengan props baru
    useEffect(() => {
        if (isOpen) {
            setPosition({
                lat: initialLat ?? DEFAULT_LAT,
                lng: initialLng ?? DEFAULT_LNG,
            });
            setSearchQuery('');
            setSearchResults([]);
        }
    }, [isOpen, initialLat, initialLng]);

    // Reverse geocoding menggunakan Nominatim
    const reverseGeocode = useCallback(async (lat, lng) => {
        setLoadingAlamat(true);
        try {
            const res = await fetch(
                `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`,
                { headers: { 'Accept-Language': 'id' } }
            );
            const data = await res.json();
            setAlamat(data.display_name ?? `${lat.toFixed(6)}, ${lng.toFixed(6)}`);
        } catch {
            setAlamat(`${lat.toFixed(6)}, ${lng.toFixed(6)}`);
        } finally {
            setLoadingAlamat(false);
        }
    }, []);

    // Panggil reverseGeocode saat komponen pertama kali mount
    useEffect(() => {
        if (isOpen) reverseGeocode(position.lat, position.lng);
    }, [isOpen]);

    // Fungsi search geocoding dengan debounce 500ms
    const handleSearch = useCallback(async (query) => {
        const q = query ?? searchQuery;
        if (!q.trim()) return;
        setIsSearching(true);
        try {
            const res = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(q)}&limit=5&countrycodes=id`,
                { headers: { 'Accept-Language': 'id' } }
            );
            const results = await res.json();
            setSearchResults(results);
        } catch {
            setSearchResults([]);
        } finally {
            setIsSearching(false);
        }
    }, [searchQuery]);

    // Debounce search input
    const handleSearchInputChange = (e) => {
        const value = e.target.value;
        setSearchQuery(value);
        if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
        if (value.trim().length >= 3) {
            searchTimeoutRef.current = setTimeout(() => handleSearch(value), 500);
        } else {
            setSearchResults([]);
        }
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
            handleSearch();
        }
    };

    // Pilih hasil search
    const pilihHasilSearch = (item) => {
        setPosition({ lat: parseFloat(item.lat), lng: parseFloat(item.lon) });
        setSearchQuery(item.display_name);
        setSearchResults([]);
        reverseGeocode(parseFloat(item.lat), parseFloat(item.lon));
    };

    // Lokasi saat ini
    const gunakanLokasiSaya = () => {
        navigator.geolocation.getCurrentPosition(
            ({ coords }) => {
                setPosition({ lat: coords.latitude, lng: coords.longitude });
                reverseGeocode(coords.latitude, coords.longitude);
            },
            () => alert('Tidak dapat mengakses lokasi. Pastikan izin lokasi diaktifkan.')
        );
    };

    // Jangan render jika modal tidak terbuka
    if (!isOpen) return null;

    return (
        /* Overlay gelap menutup seluruh layar */
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
            {/* Card modal */}
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto animate-in">
                {/* §1 — Header */}
                <div className="flex items-start justify-between p-5 pb-4">
                    <div className="flex items-center space-x-3.5">
                        <div className="bg-blue-100 p-2.5 rounded-xl text-blue-600 flex-shrink-0">
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            </svg>
                        </div>
                        <div>
                            <h3 className="text-base font-bold text-gray-800">Pilih Lokasi Kantin</h3>
                            <p className="text-sm text-gray-500 mt-0.5">Tentukan koordinat lokasi fisik kantin Anda</p>
                        </div>
                    </div>
                    <button
                        type="button"
                        onClick={onClose}
                        className="text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg p-1.5 transition-colors flex-shrink-0"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>

                {/* §2 — Search Bar */}
                <div className="px-5 pb-4 relative">
                    <div className="relative">
                        <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                            </svg>
                        </div>
                        <input
                            type="text"
                            className="w-full pl-10 pr-4 py-2.5 bg-gray-100 border border-gray-200 rounded-xl text-sm text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-300 focus:border-blue-300 transition-all"
                            placeholder="Cari alamat atau gedung..."
                            value={searchQuery}
                            onChange={handleSearchInputChange}
                            onKeyDown={handleKeyDown}
                        />
                        {isSearching && (
                            <div className="absolute inset-y-0 right-0 pr-3.5 flex items-center">
                                <svg className="w-4 h-4 animate-spin text-blue-500" fill="none" viewBox="0 0 24 24">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                                </svg>
                            </div>
                        )}
                    </div>

                    {/* Dropdown hasil pencarian */}
                    {searchResults.length > 0 && (
                        <div className="absolute left-5 right-5 top-full mt-1 bg-white border border-gray-200 rounded-xl shadow-lg z-50 max-h-48 overflow-y-auto">
                            {searchResults.map((item, idx) => (
                                <button
                                    key={idx}
                                    type="button"
                                    onClick={() => pilihHasilSearch(item)}
                                    className="w-full text-left px-4 py-2.5 text-sm text-gray-700 hover:bg-blue-50 hover:text-blue-700 transition-colors flex items-start space-x-2.5 border-b border-gray-50 last:border-b-0"
                                >
                                    <svg className="w-4 h-4 text-gray-400 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                    </svg>
                                    <span className="line-clamp-2">{item.display_name}</span>
                                </button>
                            ))}
                        </div>
                    )}
                </div>

                {/* §3 — Peta Leaflet.js Interaktif */}
                <div className="px-5 pb-4 relative">
                    <div className="rounded-xl overflow-hidden border border-gray-200">
                        <MapContainer
                            center={[position.lat, position.lng]}
                            zoom={15}
                            style={{ height: '300px', width: '100%' }}
                            zoomControl={true}
                        >
                            <TileLayer
                                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            />
                            <Marker position={[position.lat, position.lng]} icon={customIcon}>
                                <Tooltip direction="top" offset={[0, -42]} permanent>
                                    Lokasi Terpilih
                                </Tooltip>
                            </Marker>
                            <MapClickHandler onMapClick={(lat, lng) => {
                                setPosition({ lat, lng });
                                reverseGeocode(lat, lng);
                            }} />
                            <MapCenterSync position={position} />
                        </MapContainer>
                    </div>

                    {/* Tombol "Lokasi Saya" (⊙) di kiri bawah peta */}
                    <button
                        type="button"
                        onClick={gunakanLokasiSaya}
                        className="absolute bottom-8 left-8 z-[1000] w-9 h-9 bg-white border border-gray-300 rounded-full shadow-md flex items-center justify-center text-gray-600 hover:bg-gray-50 hover:text-blue-600 transition-colors"
                        title="Gunakan lokasi saya"
                    >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <circle cx="12" cy="12" r="3" strokeWidth="2"></circle>
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 2v4m0 12v4m10-10h-4M6 12H2"></path>
                        </svg>
                    </button>
                </div>

                {/* §4 — Info box alamat */}
                <div className="px-5 pb-4">
                    <div className="bg-blue-50 border border-blue-100 rounded-xl px-4 py-3 flex items-start space-x-3">
                        <div className="text-blue-500 mt-0.5 flex-shrink-0">
                            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"></path>
                            </svg>
                        </div>
                        <p className="text-sm text-blue-800 font-medium leading-snug">
                            {loadingAlamat ? 'Memuat alamat...' : alamat}
                        </p>
                    </div>
                </div>

                {/* §5 — Footer Modal */}
                <div className="flex items-center justify-between px-5 py-4 border-t border-gray-100 bg-gray-50/50 rounded-b-2xl">
                    {/* Hint kiri */}
                    <div className="hidden sm:flex items-center space-x-1.5 text-xs text-gray-400">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        <span>Geser peta untuk mengubah posisi pin</span>
                    </div>

                    {/* Tombol kanan */}
                    <div className="flex items-center space-x-3 ml-auto">
                        <button
                            type="button"
                            onClick={onClose}
                            className="px-4 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 flex items-center gap-1.5 font-medium transition-colors"
                        >
                            <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path>
                            </svg>
                            Batal
                        </button>
                        <button
                            type="button"
                            onClick={() => onConfirm({ lat: position.lat, lng: position.lng, alamat })}
                            className="px-5 py-2 text-sm bg-orange-500 hover:bg-orange-600 text-white rounded-lg flex items-center gap-2 font-medium transition-colors shadow-sm"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                            </svg>
                            Konfirmasi Lokasi
                            <span>→</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
