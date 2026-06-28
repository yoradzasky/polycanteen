import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/location_permission_sheet.dart';
import '../../features/scanner/screens/qr_scanner_screen.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class FirebaseTrackingService {
  static Future<void> updateLocation(String pesananId, double lat, double lng) async {
    try {
      final ref = FirebaseDatabase.instance.ref('deliveries/$pesananId/location');
      await ref.set({
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Location updated to Firebase for pesanan $pesananId');
    } catch (e) {
      debugPrint('Failed to update location to Firebase: $e');
    }
  }
}

class DeliveryInfo {
  final String buyerName;
  final String? buyerNote;
  final String queueNumber;
  final String originLabel;
  final double destinationLat;
  final double destinationLng;
  final String destinationLabel;
  final List<Map<String, dynamic>> orderItems;

  DeliveryInfo({
    required this.buyerName,
    this.buyerNote,
    required this.queueNumber,
    required this.originLabel,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationLabel,
    required this.orderItems,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      buyerName: json['buyer_name'] ?? '',
      buyerNote: json['buyer_note'],
      queueNumber: json['queue_number'] ?? '',
      originLabel: json['origin']?['label'] ?? '',
      destinationLat: double.tryParse(json['destination']?['lat']?.toString() ?? '') ?? 0.0,
      destinationLng: double.tryParse(json['destination']?['lng']?.toString() ?? '') ?? 0.0,
      destinationLabel: json['destination']?['label'] ?? '',
      orderItems: List<Map<String, dynamic>>.from(json['order_items'] ?? []),
    );
  }
}

class DeliveryTrackingScreen extends StatefulWidget {
  final String pesananId;

  const DeliveryTrackingScreen({super.key, required this.pesananId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  bool _isLoading = true;
  DeliveryInfo? _deliveryInfo;
  Position? _currentPosition;
  double _distanceKm = 0.0;
  int _etaMinutes = 0;

  StreamSubscription<Position>? _positionStreamSub;
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;
  final MapController _mapController = MapController();
  void Function(FlutterErrorDetails)? _originalOnError;

  @override
  void initState() {
    super.initState();
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    // Remove /mobile from baseUrl if needed, similar to what other files do
    final cleanBase = baseUrl.replaceAll(RegExp(r'/mobile$'), '');
    _dio = Dio(BaseOptions(
      baseUrl: cleanBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));

    // Intercept the NaN error from flutter_map gesture handling
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('not finite')) {
        debugPrint('[DeliveryTracking] Suppressed NaN map error');
        return; // Silently ignore NaN errors from map gestures
      }
      _originalOnError?.call(details);
    };
    
    _initDataAndLocation();
  }

  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _initDataAndLocation() async {
    await _fetchDeliveryInfo();
    if (_deliveryInfo != null) {
      await _setupLocation();
    }
  }

  Future<void> _fetchDeliveryInfo() async {
    try {
      final response = await _dio.get(
        '/pemilik/deliveries/${widget.pesananId}',
        options: await _authOptions(),
      );
      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _deliveryInfo = DeliveryInfo.fromJson(response.data);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data pesanan: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setupLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      showPermissionErrorDialog(
        context,
        title: 'Layanan Lokasi Tidak Aktif',
        message: 'Aktifkan layanan lokasi di pengaturan HP Anda untuk melanjutkan pengantaran.',
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    
    // Jika belum pernah meminta izin, tampilkan popup cantik dulu
    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      final granted = await showLocationPermissionSheet(context);
      if (granted != true) {
        if (mounted) Navigator.pop(context);
        return;
      }
      
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        showPermissionErrorDialog(
          context,
          title: 'Izin Lokasi Ditolak',
          message: 'Izinkan akses lokasi agar pengantaran bisa dilacak oleh pelanggan.',
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showPermissionErrorDialog(
        context,
        title: 'Izin Lokasi Ditolak Permanen',
        message: 'Mohon izinkan akses lokasi di pengaturan HP Anda agar fitur pengantaran dapat berjalan.',
        showOpenSettings: true,
      );
      return;
    }

    // Dapatkan posisi SEKARANG JUGA tanpa menunggu jalan 5 meter
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        FirebaseTrackingService.updateLocation(widget.pesananId, position.latitude, position.longitude);

        if (_deliveryInfo != null) {
          final distanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _deliveryInfo!.destinationLat,
            _deliveryInfo!.destinationLng,
          );
          
          setState(() {
            _distanceKm = distanceMeters / 1000.0;
            _etaMinutes = (_distanceKm / 5.0 * 60).ceil();
          });
        }
      }
    } catch (_) {}

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null && mounted) {
          setState(() {
            _currentPosition = position;
          });
          
          FirebaseTrackingService.updateLocation(widget.pesananId, position.latitude, position.longitude);

          if (_deliveryInfo != null) {
            final distanceMeters = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              _deliveryInfo!.destinationLat,
              _deliveryInfo!.destinationLng,
            );
            
            setState(() {
              _distanceKm = distanceMeters / 1000.0;
              _etaMinutes = (_distanceKm / 5.0 * 60).ceil();
            });
          }
        }
      }
    );
  }

  Future<void> _scanQrAndConfirm() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(returnMode: true),
      ),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      _confirmDelivery(scannedCode);
    }
  }

  Future<void> _confirmDelivery(String qrToken) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: AppLoadingAnimation()),
    );

    try {
      final response = await _dio.post(
        '/pemilik/deliveries/${widget.pesananId}/confirm',
        data: {'qr_token': qrToken},
        options: await _authOptions(),
      );

      if (mounted) {
        Navigator.pop(context); // close loading dialog
      }

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengantaran berhasil dikonfirmasi!'),
              backgroundColor: Colors.green,
            ),
          );
          _positionStreamSub?.cancel();
          Navigator.pop(context); // go back
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        final msg = e.response?.data?['message'] ?? 'Gagal konfirmasi pesanan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _mapController.dispose();
    // Restore original error handler
    if (_originalOnError != null) {
      FlutterError.onError = _originalOnError;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: const Center(child: AppLoadingAnimation()),
      );
    }

    if (_deliveryInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengantaran')),
        body: const Center(child: Text('Gagal memuat data pengantaran')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // FlutterMap
          Positioned.fill(
            child: _buildMap(),
          ),

          // Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildHeader()),
          ),

          // Draggable Bottom Sheet
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final destLat = _deliveryInfo!.destinationLat;
    final destLng = _deliveryInfo!.destinationLng;

    final bool isDestValid = destLat.isFinite && destLng.isFinite;
    final bool isCurrentValid = _currentPosition != null && 
                                _currentPosition!.latitude.isFinite && 
                                _currentPosition!.longitude.isFinite;

    final initialCenter = isCurrentValid
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : (isDestValid ? LatLng(destLat, destLng) : const LatLng(-7.33, 110.49));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 16.0,
        minZoom: 3.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-85.05, -180.0),
            const LatLng(85.05, 180.0),
          ),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
                 InteractiveFlag.flingAnimation |
                 InteractiveFlag.pinchZoom |
                 InteractiveFlag.doubleTapZoom |
                 InteractiveFlag.doubleTapDragZoom |
                 InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        if (isCurrentValid && isDestValid)
          PolylineLayer(
            polylines: <Polyline<Object>>[
              Polyline(
                points: [
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  LatLng(destLat, destLng),
                ],
                color: Colors.indigo.withValues(alpha: 0.6),
                strokeWidth: 5.0,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // Destination Marker (Orange)
            if (isDestValid)
              Marker(
                point: LatLng(destLat, destLng),
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Colors.orange, size: 40),
              ),
            // Current Location Marker (Red)
            if (isCurrentValid)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: const Center(
                    child: Icon(Icons.my_location, color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Pengantaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DALAM PERJALANAN',
                      style: TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.18,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.18, 0.40, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    _deliveryInfo!.buyerName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _deliveryInfo!.queueNumber,
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${(_distanceKm * 1000).toStringAsFixed(0)} m ($_etaMinutes min)',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Pesanan List
              const Text('PESANAN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _deliveryInfo!.orderItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${item['qty']}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Timeline
              _buildTimelineItem(isFirst: true, title: 'Sudah Diterima', subtitle: _deliveryInfo!.originLabel, color: Colors.indigo),
              _buildTimelineItem(isFirst: false, title: 'Tujuan Pengantaran', subtitle: _deliveryInfo!.destinationLabel, color: Colors.orange),
              
              if (_deliveryInfo!.buyerNote != null && _deliveryInfo!.buyerNote!.isNotEmpty)
                const SizedBox(height: 16),

              // Buyer Note
              if (_deliveryInfo!.buyerNote != null && _deliveryInfo!.buyerNote!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Catatan Pembeli', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('"${_deliveryInfo!.buyerNote}"', style: const TextStyle(color: Colors.black87, fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Scan QR Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _scanQrAndConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Scan QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem({required bool isFirst, required String title, required String subtitle, required Color color}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(isFirst ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 20),
              if (isFirst)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
                if (isFirst) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

