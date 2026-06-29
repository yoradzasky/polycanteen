import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/payment_service.dart';
import '../../orders/screens/queue_ticket_screen.dart';
import '../../orders/services/order_service.dart';
import 'qris_payment_screen.dart';
import '../../../seller/tracking/widgets/location_permission_sheet.dart';
import '../../../core/layouts/student_main_layout.dart';
import 'location_picker_screen.dart';
import '../../home/widgets/custom_snackbar.dart';

class PaymentScreen extends StatefulWidget {
  final int pesananId;
  final double totalHarga;

  const PaymentScreen({super.key, required this.pesananId, required this.totalHarga});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  bool _isLoadingDetails = true;
  String _selectedMethod = 'qris';
  String _selectedOrderType = 'Makan di Tempat';
  List<dynamic> _orderItems = [];
  String _orderStatus = 'pending';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double? _latitude;
  double? _longitude;
  Timer? _statusTimer;
  bool _isGettingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() => _isLoadingDetails = true);
      final details = await _orderService.getOrderDetail(widget.pesananId);
      setState(() {
        _orderItems = details['detail_pesanan'] ?? [];
        _selectedOrderType = _formatOrderType(details['tipe_pesanan'] ?? 'dine_in');
        _orderStatus = details['status_pesanan'] ?? 'pending';
        if (details['catatan_pesanan'] != null) {
          _noteController.text = details['catatan_pesanan'];
        }
        if (details['alamat_pengantaran'] != null) {
          _addressController.text = details['alamat_pengantaran'];
        }
        _isLoadingDetails = false;
      });

      // Jika statusnya menunggu_persetujuan, mulai polling!
      if (_orderStatus == 'menunggu_persetujuan' && _statusTimer == null) {
        _startStatusPolling();
      }
    } catch (e) {
      print('DEBUG: Error loading order details: $e');
      setState(() => _isLoadingDetails = false);
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final details = await _orderService.getOrderDetail(widget.pesananId);
        final newStatus = details['status_pesanan'] ?? 'pending';
        if (newStatus != _orderStatus) {
          setState(() {
            _orderStatus = newStatus;
          });
          if (_orderStatus == 'menunggu_pembayaran') {
            _stopStatusPolling();
            CustomSnackBar.show(
              context,
              message: 'Pesanan Anda disetujui! Silakan lakukan pembayaran.',
              isSuccess: true,
            );
          } else if (_orderStatus == 'ditolak') {
            _stopStatusPolling();
            _showRejectionDialog(details['alasan_penolakan'] ?? 'Bahan makanan habis');
          }
        }
      } catch (e) {
        print('DEBUG: Polling error: $e');
      }
    });
  }

  void _stopStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  void _showRejectionDialog(String alasan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pesanan Ditolak', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Maaf, penjual menolak pesanan Anda.\nAlasan: $alasan'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali
            },
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndRequestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        showPermissionErrorDialog(
          context,
          title: 'Layanan Lokasi Mati',
          message: 'Aktifkan GPS Anda untuk menggunakan layanan pengantaran.',
        );
        setState(() => _selectedOrderType = 'Makan di Tempat');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        final granted = await showLocationPermissionSheet(
          context,
          title: 'Mau pesananmu diantar tepat ke lokasimu?',
          description: 'Bagikan lokasimu sekarang agar kurir dapat menemukan alamatmu dengan mudah.',
        );
        if (granted == true) {
          permission = await Geolocator.requestPermission();
        } else {
          setState(() => _selectedOrderType = 'Makan di Tempat');
          return;
        }
      }

      if (permission == LocationPermission.denied) {
        setState(() => _selectedOrderType = 'Makan di Tempat');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        showPermissionErrorDialog(
          context,
          title: 'Izin Lokasi Ditolak Permanen',
          message: 'Mohon izinkan akses lokasi di pengaturan HP Anda agar fitur pengantaran dapat berjalan.',
          showOpenSettings: true,
        );
        setState(() => _selectedOrderType = 'Makan di Tempat');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _selectedOrderType = 'Makan di Tempat');
    }
  }

  Future<void> _fetchAndFillAddressFromGps() async {
    if (_isGettingAddress) return;
    setState(() => _isGettingAddress = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Mendapatkan alamat lokasi Anda...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        showPermissionErrorDialog(
          context,
          title: 'Layanan Lokasi Mati',
          message: 'Aktifkan GPS Anda untuk menggunakan layanan pengantaran.',
        );
        setState(() => _isGettingAddress = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        final granted = await showLocationPermissionSheet(
          context,
          title: 'Mau pesananmu diantar tepat ke lokasimu?',
          description: 'Bagikan lokasimu sekarang agar kurir dapat menemukan alamatmu dengan mudah.',
        );
        if (granted == true) {
          permission = await Geolocator.requestPermission();
        } else {
          setState(() => _isGettingAddress = false);
          return;
        }
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isGettingAddress = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'polycanteen-mobile-app'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name']?.toString() ?? '';
        if (displayName.isNotEmpty) {
          setState(() {
            _addressController.text = displayName;
          });
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Alamat berhasil diisi sesuai lokasi Anda!',
              isSuccess: true,
            );
          }
        } else {
          throw 'Alamat tidak ditemukan';
        }
      } else {
        throw 'Gagal mendapatkan data alamat';
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      if (mounted) {
        if (_latitude != null && _longitude != null) {
          setState(() {
            _addressController.text = 'Koordinat: $_latitude, $_longitude';
          });
          CustomSnackBar.show(
            context,
            message: 'Gagal menerjemahkan lokasi. Menggunakan koordinat saja.',
          );
        } else {
          CustomSnackBar.show(
            context,
            message: 'Gagal mendapatkan lokasi: $e',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingAddress = false);
      }
    }
  }

  Future<void> _handleSubmitOrder() async {
    if (_selectedOrderType == 'Pengantaran' && _addressController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Mohon masukkan alamat lengkap pengantaran.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _orderService.submitOrder(
        widget.pesananId,
        tipePesanan: _selectedOrderType,
        alamatPengantaran: _selectedOrderType == 'Pengantaran' ? _addressController.text.trim() : null,
        destLat: _selectedOrderType == 'Pengantaran' ? _latitude : null,
        destLng: _selectedOrderType == 'Pengantaran' ? _longitude : null,
        catatanPesanan: _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentMainLayout(
              userRole: 'mahasiswa',
              initialIndex: 2,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          message: 'Gagal mengajukan pesanan: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleCancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _orderService.cancelOrder(widget.pesananId);
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Pesanan berhasil dibatalkan',
          isSuccess: true,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentMainLayout(
              userRole: 'mahasiswa',
              initialIndex: 2,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          message: 'Gagal membatalkan pesanan: $e',
          isError: true,
        );
      }
    }
  }

  String _formatOrderType(String type) {
    switch (type.toLowerCase()) {
      case 'takeaway':
      case 'take_away':
      case 'bungkus':
        return 'Bungkus';
      case 'delivery':
      case 'pengantaran':
        return 'Pengantaran';
      default:
        return 'Makan di Tempat';
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _handlePayment() async {
    print('DEBUG: Starting payment process for pesananId: ${widget.pesananId} with method: $_selectedMethod');
    setState(() => _isLoading = true);
    try {
      final result = await _paymentService.createPayment(
        widget.pesananId,
        paymentType: _selectedMethod,
      );
      print('DEBUG: Payment API Result: $result');
      
      final data = result['data'];
      final paymentType = data['payment_type'];

      if (mounted) {
        if (paymentType == 'qris') {
          final qrString = data['qr_string'];
          if (qrString == null || qrString.isEmpty) {
            throw 'Data QRIS tidak ditemukan';
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QrisPaymentScreen(
                qrUrl: qrString,
                pesananId: widget.pesananId,
                totalAmount: _formatCurrency(widget.totalHarga),
              ),
            ),
          );
        } else {
          final paymentUrl = data['payment_url'];
          if (paymentUrl == null || paymentUrl.isEmpty) {
            throw 'URL pembayaran tidak ditemukan';
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SnapWebViewScreen(
                url: paymentUrl,
                onFinished: () {
                  print('DEBUG: Payment finished, navigating to ticket');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QueueTicketScreen(pesananId: widget.pesananId),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Payment Error: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "Gagal membuat pembayaran: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _stopStatusPolling();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTotal = _formatCurrency(widget.totalHarga);

    // Tentukan teks tombol dan aksi
    String buttonText = 'Bayar Sekarang - $formattedTotal';
    IconData buttonIcon = Icons.credit_card;
    VoidCallback? buttonAction = _handlePayment;
    bool isButtonDisabled = _isLoading;

    if (_orderStatus == 'pending') {
      buttonText = 'Pesan Sekarang';
      buttonIcon = Icons.shopping_cart_checkout;
      buttonAction = _handleSubmitOrder;
    } else if (_orderStatus == 'menunggu_persetujuan') {
      buttonText = 'Menunggu Persetujuan Penjual...';
      buttonIcon = Icons.hourglass_empty;
      buttonAction = null;
      isButtonDisabled = true;
    } else if (_orderStatus == 'menunggu_pembayaran') {
      buttonText = 'Bayar Sekarang - $formattedTotal';
      buttonIcon = Icons.qr_code_2;
      buttonAction = _handlePayment;
    } else if (_orderStatus == 'ditolak') {
      buttonText = 'Pesanan Ditolak';
      buttonIcon = Icons.cancel;
      buttonAction = null;
      isButtonDisabled = true;
    } else {
      // Status 'dibayar', 'dimasak', dsb.
      buttonText = 'Pesanan Sedang Diproses';
      buttonIcon = Icons.info_outline;
      buttonAction = null;
      isButtonDisabled = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F2),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3852B4), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Konfirmasi Pesanan',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingDetails
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B5BBD)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OrderTypeSelector(
                  selectedType: _selectedOrderType,
                  onChanged: _orderStatus == 'pending'
                      ? (type) {
                          setState(() => _selectedOrderType = type);
                          if (type == 'Pengantaran') {
                            _checkAndRequestLocation();
                          }
                        }
                      : (type) {}, // Disable editing type once submitted
                ),
                const SizedBox(height: 24),

                if (_selectedOrderType == 'Pengantaran') ...[
                  const SectionTitle(title: 'Alamat Pengantaran'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _addressController,
                      enabled: _orderStatus == 'pending', // Disable editing once submitted
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat lengkap pengantaran...',
                        border: InputBorder.none,
                        suffixIcon: _orderStatus == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isGettingAddress)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B5BBD)),
                                      ),
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(Icons.my_location, color: Color(0xFF3B5BBD)),
                                      tooltip: 'Ambil lokasi saat ini',
                                      onPressed: _fetchAndFillAddressFromGps,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.map, color: Color(0xFF3B5BBD)),
                                      tooltip: 'Pilih lokasi dari peta',
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LocationPickerScreen(
                                              initialLat: _latitude,
                                              initialLng: _longitude,
                                            ),
                                          ),
                                        );
                                        if (result != null && result is Map<String, dynamic>) {
                                          setState(() {
                                            _addressController.text = result['address'] ?? '';
                                            _latitude = result['lat'];
                                            _longitude = result['lng'];
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SectionTitle(title: 'Catatan Pesanan'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _noteController,
                    enabled: _orderStatus == 'pending', // Disable editing once submitted
                    decoration: const InputDecoration(
                      hintText: 'Tambah catatan (cth: Sendok, Jangan pedas)...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_orderItems.isNotEmpty) ...[
                  const SectionTitle(title: 'Pesanan Anda'),
                  ..._orderItems.map((item) {
                    final menu = item['menu'] ?? {};
                    final name = menu['nama_item'] ?? '-';
                    final priceVal = double.tryParse(item['harga_saat_beli']?.toString() ?? '0') ?? 0;
                    final qty = int.tryParse(item['jumlah_pesanan']?.toString() ?? '1') ?? 1;
                    final String? image = menu['foto_menu'];
                    return OrderItemCard(
                      name: name,
                      price: _formatCurrency(priceVal),
                      qty: qty,
                      imagePath: image,
                      varianSnapshot: item['varian_snapshot'],
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                
                if (_orderStatus == 'menunggu_pembayaran' || _orderStatus == 'pending' || _orderStatus == 'menunggu_persetujuan') ...[
                  const SectionTitle(title: 'Metode Pembayaran'),
                  PaymentMethodSelectorHorizontal(
                    selectedMethod: _selectedMethod,
                    onChanged: (method) {
                      setState(() => _selectedMethod = method);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                
                PaymentSummaryCard(
                  subtotal: formattedTotal,
                  total: formattedTotal,
                  totalItems: _orderItems.fold<int>(0, (sum, item) {
                    final qty = int.tryParse(item['jumlah_pesanan']?.toString() ?? '1') ?? 1;
                    return sum + qty;
                  }),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isButtonDisabled ? null : buttonAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BBD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(buttonIcon, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class OrderItemCard extends StatelessWidget {
  final String name, price;
  final String? imagePath;
  final int qty;
  final dynamic varianSnapshot;
  const OrderItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.qty,
    this.imagePath,
    this.varianSnapshot,
  });

  List<Widget> _buildVarianList(dynamic snapshot) {
    List<Widget> children = [];
    if (snapshot == null) return children;

    try {
      if (snapshot is Map) {
        snapshot.forEach((key, val) {
          if (val is Map) {
            final optionName = val['nama'] ?? val['name'] ?? '';
            if (optionName.toString().isNotEmpty) {
              children.add(
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• $key: $optionName',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }
          } else if (val is List) {
            for (var item in val) {
              if (item is Map) {
                final optionName = item['nama'] ?? item['name'] ?? '';
                if (optionName.toString().isNotEmpty) {
                  children.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• $key: $optionName',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  );
                }
              } else {
                children.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $key: $item',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                );
              }
            }
          } else if (val != null) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $key: $val',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }
        });
      } else if (snapshot is List) {
        for (var item in snapshot) {
          final optionName = item is Map
              ? (item['nama'] ?? item['name'] ?? item.toString())
              : item.toString();
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $optionName',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing variant snapshot: $e');
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath != null && imagePath!.startsWith('http')
                    ? Image.network(
                        imagePath!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, color: Colors.grey, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, color: Colors.grey, size: 30),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (varianSnapshot != null) ...[
                      const SizedBox(height: 2),
                      ..._buildVarianList(varianSnapshot),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.remove, size: 16, color: Color(0xFF6B7280)),
                      onPressed: () {},
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFF3B5BBD)),
                      onPressed: () {},
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Tambah catatan (cth: Jangan pedas)...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final String subtotal, total;
  final int totalItems;
  const PaymentSummaryCard({super.key, required this.subtotal, required this.total, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal ($totalItems item)', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              Text(subtotal, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biaya Layanan', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const Text('Rp 0', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE5E7EB)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                total,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;
  
  const OrderTypeSelector({super.key, required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTypeItem('Makan di Tempat', Icons.restaurant),
          _buildTypeItem('Bungkus', Icons.shopping_bag_outlined),
          _buildTypeItem('Pengantaran', Icons.motorcycle_outlined),
        ],
      ),
    );
  }

  Widget _buildTypeItem(String title, IconData icon) {
    bool isSelected = selectedType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF19E42) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 18),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentMethodSelectorHorizontal extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onChanged;

  const PaymentMethodSelectorHorizontal({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B5BBD), Color(0xFF4C6ED7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5BBD).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QRIS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Bayar instan via e-wallet & bank',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class SnapWebViewScreen extends StatefulWidget {
  final String url;
  final VoidCallback onFinished;

  const SnapWebViewScreen({super.key, required this.url, required this.onFinished});

  @override
  State<SnapWebViewScreen> createState() => _SnapWebViewScreenState();
}

class _SnapWebViewScreenState extends State<SnapWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (url.contains('finish') || url.contains('error') || url.contains('close')) {
              widget.onFinished();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proses Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
