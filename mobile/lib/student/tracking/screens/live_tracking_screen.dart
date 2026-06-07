import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class CourierLocation {
  final double lat;
  final double lng;
  final int updatedAt;

  CourierLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });
}

class FirebaseTrackingService {
  static Stream<CourierLocation?> watchLocation(String pesananId) {
    return FirebaseDatabase.instance
        .ref('deliveries/$pesananId/location')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data is Map) {
            return CourierLocation(
              lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
              lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
              updatedAt: (data['updated_at'] as num?)?.toInt() ?? 0,
            );
          }
          return null;
        });
  }
}

class DeliveryInfo {
  final String courierName;
  final String? buyerNote;
  final String queueNumber;
  final String status;
  final String originLabel;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final String destinationLabel;
  final List<Map<String, dynamic>> orderItems;

  DeliveryInfo({
    required this.courierName,
    this.buyerNote,
    required this.queueNumber,
    required this.status,
    required this.originLabel,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationLabel,
    required this.orderItems,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      courierName: json['courier_name'] ?? 'Pengantar',
      buyerNote: json['buyer_note'],
      queueNumber: json['queue_number'] ?? '',
      status: json['status'] ?? '',
      originLabel: json['origin']?['label'] ?? '',
      originLat: double.tryParse(json['origin']?['lat']?.toString() ?? '') ?? 0.0,
      originLng: double.tryParse(json['origin']?['lng']?.toString() ?? '') ?? 0.0,
      destinationLat: double.tryParse(json['destination']?['lat']?.toString() ?? '') ?? 0.0,
      destinationLng: double.tryParse(json['destination']?['lng']?.toString() ?? '') ?? 0.0,
      destinationLabel: json['destination']?['label'] ?? '',
      orderItems: List<Map<String, dynamic>>.from(json['order_items'] ?? []),
    );
  }
}

class LiveTrackingScreen extends StatefulWidget {
  final String pesananId;

  const LiveTrackingScreen({super.key, required this.pesananId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  DeliveryInfo? _deliveryInfo;
  CourierLocation? _courierLocation;
  String? _errorMessage;

  StreamSubscription<CourierLocation?>? _locationSub;
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;
  final MapController _mapController = MapController();

  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  void Function(FlutterErrorDetails)? _originalOnError;

  @override
  void initState() {
    super.initState();
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    final cleanBase = baseUrl.replaceAll(RegExp(r'/mobile$'), '');
    _dio = Dio(
      BaseOptions(
        baseUrl: cleanBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Intercept the NaN error from flutter_map gesture handling
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('not finite')) {
        debugPrint('[LiveTracking] Suppressed NaN map error');
        return; // Silently ignore NaN errors from map gestures
      }
      _originalOnError?.call(details);
    };

    _initData();
  }

  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _initData() async {
    try {
      final response = await _dio.get(
        '/deliveries/${widget.pesananId}',
        options: await _authOptions(),
      );
      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _deliveryInfo = DeliveryInfo.fromJson(response.data);
            _isLoading = false;
          });
          _startWatchingLocation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengambil data pesanan: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startWatchingLocation() {
    _locationSub = FirebaseTrackingService.watchLocation(widget.pesananId)
        .listen((location) {
          if (location != null && mounted) {
            setState(() {
              _courierLocation = location;
            });
            _updateDistanceAndEta(location);
            _animateCameraTo(LatLng(location.lat, location.lng));
          }
        });
  }

  void _updateDistanceAndEta(CourierLocation location) {
    if (_deliveryInfo == null) return;

    final distanceMeters = Geolocator.distanceBetween(
      location.lat,
      location.lng,
      _deliveryInfo!.destinationLat,
      _deliveryInfo!.destinationLng,
    );

    setState(() {
      _distanceKm = distanceMeters / 1000.0;
      _etaMinutes = (_distanceKm / 5.0 * 60).ceil();
    });
  }

  void _animateCameraTo(LatLng dest, {double zoom = 16.0}) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
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
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Tracking')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initData();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // FlutterMap
          Positioned.fill(child: _buildMap()),

          // Top Header & Bottom Sheet
          SafeArea(child: Column(children: [_buildHeader(), const Spacer()])),

          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final destLat = _deliveryInfo!.destinationLat;
    final destLng = _deliveryInfo!.destinationLng;
    final originLat = _deliveryInfo!.originLat;
    final originLng = _deliveryInfo!.originLng;

    final bool isDestValid = destLat.isFinite && destLng.isFinite;
    final bool isOriginValid = originLat.isFinite && originLng.isFinite;
    final bool isCourierValid = _courierLocation != null && 
                                _courierLocation!.lat.isFinite && 
                                _courierLocation!.lng.isFinite;

    // Initial center is courier if available, otherwise origin
    final initialCenter = isCourierValid
        ? LatLng(_courierLocation!.lat, _courierLocation!.lng)
        : (isOriginValid ? LatLng(originLat, originLng) : const LatLng(-7.33, 110.49));

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
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        if (isOriginValid && isDestValid)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  LatLng(originLat, originLng),
                  if (isCourierValid)
                    LatLng(_courierLocation!.lat, _courierLocation!.lng),
                  LatLng(destLat, destLng),
                ],
                color: Colors.blue.withValues(alpha: 0.6),
                strokeWidth: 5.0,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Kantin / Origin Marker (White/Grey)
            if (isOriginValid)
              Marker(
                point: LatLng(originLat, originLng),
                width: 100,
                height: 60,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.indigo,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: Text(
                        _deliveryInfo!.originLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Destination Marker (Orange)
            if (isDestValid)
              Marker(
                point: LatLng(destLat, destLng),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
            // Courier Marker (Red)
            if (isCourierValid)
              Marker(
                point: LatLng(_courierLocation!.lat, _courierLocation!.lng),
                width: 40,
                height: 40,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      'DALAM PERJALANAN',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildBottomSheet() {
    final isArrived = _deliveryInfo!.status == 'selesai';

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      _deliveryInfo!.courierName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _deliveryInfo!.queueNumber,
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                      _courierLocation != null
                          ? '${(_distanceKm * 1000).toStringAsFixed(0)} m ($_etaMinutes min)'
                          : 'Mencari lokasi pengantar...',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Pesanan List
                const Text(
                  'PESANAN',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item['qty']}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                // Timeline
                _buildTimelineItem(
                  isFirst: true,
                  isLast: false,
                  title: 'Sudah Diterima & Dimasak',
                  subtitle: _deliveryInfo!.originLabel,
                  color: Colors.indigo,
                  icon: Icons.check_circle,
                  isActive: true,
                ),
                _buildTimelineItem(
                  isFirst: false,
                  isLast: false,
                  title: 'Tujuan Pengantaran',
                  subtitle: _deliveryInfo!.destinationLabel,
                  color: Colors.orange,
                  icon: Icons.radio_button_unchecked,
                  isActive: true,
                  isPulsing: !isArrived,
                ),
                _buildTimelineItem(
                  isFirst: false,
                  isLast: true,
                  title: 'Pesanan Sudah Diterima',
                  subtitle: '',
                  color: isArrived ? Colors.green : Colors.grey,
                  icon: isArrived
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  isActive: isArrived,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required bool isFirst,
    required bool isLast,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isActive,
    bool isPulsing = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (isPulsing)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(icon, color: color, size: 20),
                    );
                  },
                )
              else
                Icon(icon, color: color, size: 20),

              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive
                        ? color.withValues(alpha: 0.5)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
