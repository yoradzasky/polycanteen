import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../student/tracking/screens/live_tracking_screen.dart'
    show CourierLocation;
import '../../../tracking/screens/delivery_tracking_screen.dart'
    show FirebaseTrackingService, DeliveryTrackingScreen;

class DeliveryTrackingCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onScanQr;
  final Color primaryColor;

  const DeliveryTrackingCard({
    super.key,
    required this.order,
    this.onScanQr,
    required this.primaryColor,
  });

  @override
  State<DeliveryTrackingCard> createState() => _DeliveryTrackingCardState();
}

class _DeliveryTrackingCardState extends State<DeliveryTrackingCard> {
  StreamSubscription<Position>? _positionStreamSub;
  CourierLocation? _courierLocation;
  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  bool _initialDistanceCalculated = false;

  @override
  void initState() {
    super.initState();
    _calculateInitialDistance();
    _startWatchingLocation();
  }

  /// Hitung jarak awal dari kantin ke tujuan (fallback saat kurir belum terlacak)
  void _calculateInitialDistance() {
    final originLat =
        double.tryParse(
          widget.order['kantin']?['latitude']?.toString() ?? '',
        ) ??
        0.0;
    final originLng =
        double.tryParse(
          widget.order['kantin']?['longitude']?.toString() ?? '',
        ) ??
        0.0;
    final destLat =
        double.tryParse(widget.order['dest_lat']?.toString() ?? '') ?? 0.0;
    final destLng =
        double.tryParse(widget.order['dest_lng']?.toString() ?? '') ?? 0.0;

    if (originLat != 0 && originLng != 0 && destLat != 0 && destLng != 0) {
      final distanceMeters = Geolocator.distanceBetween(
        originLat,
        originLng,
        destLat,
        destLng,
      );
      setState(() {
        _distanceKm = distanceMeters / 1000.0;
        _etaMinutes = (_distanceKm / 5.0 * 60).ceil();
        if (_etaMinutes < 1) _etaMinutes = 1;
        _initialDistanceCalculated = true;
      });
    }
  }

  Future<void> _startWatchingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    // Dapatkan posisi SATU KALI dengan cepat agar ETA langsung update tanpa harus jalan 5 meter dulu
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        final loc = CourierLocation(
          lat: position.latitude,
          lng: position.longitude,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        setState(() {
          _courierLocation = loc;
        });
        _updateDistanceAndEta(loc);
      }
    } catch (_) {}

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) {
            if (position != null && mounted) {
              final loc = CourierLocation(
                lat: position.latitude,
                lng: position.longitude,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              setState(() {
                _courierLocation = loc;
              });
              _updateDistanceAndEta(loc);

              // Update Firebase if possible, so buyer can track early
              try {
                final pesananId = widget.order['id'].toString();
                FirebaseTrackingService.updateLocation(
                  pesananId,
                  loc.lat,
                  loc.lng,
                );
              } catch (_) {}
            }
          },
        );
  }

  void _updateDistanceAndEta(CourierLocation location) {
    final destLat =
        double.tryParse(widget.order['dest_lat']?.toString() ?? '') ?? 0.0;
    final destLng =
        double.tryParse(widget.order['dest_lng']?.toString() ?? '') ?? 0.0;

    if (destLat == 0 || destLng == 0) return;

    final distanceMeters = Geolocator.distanceBetween(
      location.lat,
      location.lng,
      destLat,
      destLng,
    );

    setState(() {
      _distanceKm = distanceMeters / 1000.0;
      _etaMinutes = (_distanceKm / 5.0 * 60).ceil();
      if (_etaMinutes < 1) _etaMinutes = 1;
    });
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> details = widget.order['details'] ?? [];
    int totalItems = details.fold(
      0,
      (sum, item) =>
          sum + (int.tryParse(item['jumlah_pesanan'].toString()) ?? 1),
    );
    String itemName = 'Pesanan';
    if (details.isNotEmpty && details.first['menu'] != null) {
      itemName = details.first['menu']['nama_item']?.toString() ?? 'Pesanan';
    }
    String namaPemesan =
        widget.order['mahasiswa']?['nama_mahasiswa'] ?? 'Pelanggan';
    // Gunakan field yang benar dari database
    String alamat =
        widget.order['alamat_pengantaran'] ??
        widget.order['alamat_pengiriman'] ??
        'Alamat belum tersedia';

    String waktuPesanan = '';
    String waktuFormatted = '';
    if (widget.order['created_at'] != null) {
      try {
        final dt = DateTime.parse(widget.order['created_at']).toLocal();
        final hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        waktuPesanan = '$displayHour:$minute $ampm';
        waktuFormatted = waktuPesanan;
      } catch (_) {}
    }

    final originLat =
        double.tryParse(
          widget.order['kantin']?['latitude']?.toString() ?? '',
        ) ??
        0.0;
    final originLng =
        double.tryParse(
          widget.order['kantin']?['longitude']?.toString() ?? '',
        ) ??
        0.0;
    final destLat =
        double.tryParse(widget.order['dest_lat']?.toString() ?? '') ?? 0.0;
    final destLng =
        double.tryParse(widget.order['dest_lng']?.toString() ?? '') ?? 0.0;

    final initialCenter = _courierLocation != null
        ? LatLng(_courierLocation!.lat, _courierLocation!.lng)
        : (originLat != 0 && originLng != 0
              ? LatLng(originLat, originLng)
              : const LatLng(-7.3305, 110.5084)); // Fallback Salatiga

    final hasEta = _initialDistanceCalculated || _courierLocation != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER: Nomor Antrian + Waktu + Badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    widget.order['nomor_antrian'] ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: widget.primaryColor,
                    ),
                  ),
                  if (waktuPesanan.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        waktuPesanan,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF828282),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'DALAM PERJALANAN',
                  style: TextStyle(
                    color: Color(0xFFF2994A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Nama Item ──
          Text(
            totalItems > 1 ? '$itemName + ${totalItems - 1} Items' : itemName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F4F4F),
            ),
          ),
          const SizedBox(height: 16),

          // ── MAP ──
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBF7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0D5E8), width: 1),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        if (originLat != 0 &&
                            originLng != 0 &&
                            destLat != 0 &&
                            destLng != 0)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [
                                  LatLng(originLat, originLng),
                                  if (_courierLocation != null)
                                    LatLng(
                                      _courierLocation!.lat,
                                      _courierLocation!.lng,
                                    ),
                                  LatLng(destLat, destLng),
                                ],
                                color: Colors.blue.withValues(alpha: 0.6),
                                strokeWidth: 4.0,
                                pattern: const StrokePattern.dotted(),
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (originLat != 0 && originLng != 0)
                              Marker(
                                point: LatLng(originLat, originLng),
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.storefront,
                                    color: Colors.indigo,
                                    size: 18,
                                  ),
                                ),
                              ),
                            if (destLat != 0 && destLng != 0)
                              Marker(
                                point: LatLng(destLat, destLng),
                                width: 30,
                                height: 30,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.orange,
                                  size: 30,
                                ),
                              ),
                            if (_courierLocation != null)
                              Marker(
                                point: LatLng(
                                  _courierLocation!.lat,
                                  _courierLocation!.lng,
                                ),
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ETA Overlay
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasEta
                                ? '${(_distanceKm * 1000).toStringAsFixed(0)} m • ~$_etaMinutes min'
                                : 'Mencari lokasi...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── INFO PELANGGAN ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E9F5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaPemesan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pelanggan',
                            style: TextStyle(
                              color: Color(0xFF828282),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Alamat Pengiriman
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFF2994A),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alamat Pengiriman',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF828282),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alamat,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── PROGRES PENGIRIMAN ──
          const Text(
            'PROGRES PENGIRIMAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF828282),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),

          // Timeline Step 1: Pesanan Diterima
          _buildTimelineStep(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF3949AB),
            iconBgColor: const Color(0xFFE8EBF7),
            title: 'Pesanan Diterima',
            subtitle: waktuFormatted.isNotEmpty
                ? '$waktuFormatted · Kurir mengambil pesanan'
                : 'Kurir mengambil pesanan',
            isActive: true,
            isLast: false,
          ),

          // Timeline Step 2: Dalam Perjalanan
          _buildTimelineStep(
            icon: Icons.delivery_dining,
            iconColor: const Color(0xFFF2994A),
            iconBgColor: const Color(0xFFFFF3F0),
            title: 'Dalam Perjalanan',
            subtitle: 'Sekarang · Menuju lokasi pelanggan',
            isActive: true,
            isLast: false,
            titleColor: const Color(0xFFF2994A),
          ),

          // Timeline Step 3: Terkirim
          _buildTimelineStep(
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.grey.shade400,
            iconBgColor: Colors.grey.shade100,
            title: 'Terkirim',
            subtitle: 'Menunggu konfirmasi',
            isActive: false,
            isLast: true,
          ),

          const SizedBox(height: 20),

          // ── JARAK & ESTIMASI ──
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EBF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delivery_dining,
                        color: widget.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jarak',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF828282),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasEta
                              ? '${(_distanceKm * 1000).toStringAsFixed(0)} m'
                              : '- m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_filled,
                        color: Color(0xFFF2994A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimasi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF828282),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasEta ? '$_etaMinutes mnt' : '- mnt',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── TOMBOL LACAK PEMBELI ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final pesananId = widget.order['id']?.toString() ?? '';
                if (pesananId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DeliveryTrackingScreen(pesananId: pesananId),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lacak Pelanggan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── TOMBOL SELESAI ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onScanQr,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2994A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Scan QR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget Timeline Step
  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isLast,
    Color? titleColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isActive
                          ? const Color(0xFFD0D5E8)
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          titleColor ??
                          (isActive
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? const Color(0xFF828282)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
