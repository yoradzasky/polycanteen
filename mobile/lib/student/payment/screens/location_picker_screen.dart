import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(-6.8886, 109.6753); // Default: Pekalongan
  String _addressText = 'Geser peta untuk memilih lokasi...';
  bool _isLoadingAddress = false;
  bool _isLoadingMyLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _reverseGeocode(_selectedLocation);
    } else {
      _goToMyLocation();
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingMyLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi mati. Aktifkan GPS Anda.')),
          );
        }
        setState(() => _isLoadingMyLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')),
          );
        }
        setState(() => _isLoadingMyLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLoc;
      });
      _mapController.move(newLoc, 17.0);
      _reverseGeocode(newLoc);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMyLocation = false);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'polycanteen-mobile-app'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name']?.toString() ?? '';
        if (displayName.isNotEmpty && mounted) {
          setState(() => _addressText = displayName);
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      if (mounted) {
        setState(() {
          _addressText = 'Koordinat: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6ED),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Lokasi',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 17.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selectedLocation = position.center;
                    _addressText = 'Mendapatkan alamat...';
                    _isLoadingAddress = true;
                  });
                }
              },
              onMapEvent: (event) {
                // When user stops dragging, resolve address
                if (event is MapEventMoveEnd) {
                  _reverseGeocode(_selectedLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.polines.polycanteen',
              ),
            ],
          ),

          // ── Center Pin (fixed overlay) ──
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Lokasi Pengantaran',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFE53935),
                    size: 48,
                  ),
                ],
              ),
            ),
          ),

          // ── My Location FAB ──
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _isLoadingMyLocation ? null : _goToMyLocation,
              child: _isLoadingMyLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3A8C)),
                      ),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF2D3A8C)),
            ),
          ),

          // ── Bottom Card with Address + Confirm Button ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
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
                      const SizedBox(height: 16),
                      const Text(
                        'Alamat Pengantaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: _isLoadingAddress
                                ? Colors.grey.shade400
                                : const Color(0xFFF08D39),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isLoadingAddress
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Mendapatkan alamat...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _addressText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoadingAddress
                              ? null
                              : () {
                                  Navigator.pop(context, {
                                    'address': _addressText,
                                    'lat': _selectedLocation.latitude,
                                    'lng': _selectedLocation.longitude,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF08D39),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Gunakan Lokasi Ini',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
