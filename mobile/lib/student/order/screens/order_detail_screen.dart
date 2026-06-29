import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class OrderDetailScreen extends StatefulWidget {
  final int pesananId;

  const OrderDetailScreen({super.key, required this.pesananId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _order;

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

    _fetchOrderDetail();
  }

  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final response = await _dio.get(
        '/mahasiswa/orders/${widget.pesananId}',
        options: await _authOptions(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _order = response.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat detail pesanan';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = (double.tryParse(value.toString()) ?? 0).toInt();
    return NumberFormat('#,###', 'id_ID').format(amount);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _getBaseUrl() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    return baseUrl
        .replaceAll(RegExp(r'/api$'), '')
        .replaceAll(RegExp(r'/mobile$'), '');
  }

  Map<String, dynamic> _getOrderTypeConfig(String tipe) {
    switch (tipe) {
      case 'delivery':
        return {
          'icon': Icons.delivery_dining,
          'color': const Color(0xFF2D3A8C),
          'label': 'Delivery',
        };
      case 'take_away':
        return {
          'icon': Icons.takeout_dining,
          'color': const Color(0xFFF08D39),
          'label': 'Take Away',
        };
      case 'dine_in':
      default:
        return {
          'icon': Icons.restaurant,
          'color': const Color(0xFF4CAF50),
          'label': 'Dine In',
        };
    }
  }

  bool _isActiveStatus(String status) {
    return [
      'pending',
      'menunggu_persetujuan',
      'menunggu_pembayaran',
      'dibayar',
      'dikonfirmasi',
      'diproses',
      'dimasak',
      'siap_diambil',
      'menunggu_dikirim',
      'dalam_perjalanan',
    ].contains(status);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: const Center(child: AppLoadingAnimation()),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A2E),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Detail Pesanan',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Data tidak ditemukan',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchOrderDetail();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3A8C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _order!['status_pesanan'] ?? '';
    final nomorAntrian = _order!['nomor_antrian'] ?? '-';
    final kantinName = _order!['kantin']?['nama_kantin'] ?? '-';
    final kantinLogo = _order!['kantin']?['logo_path'];
    final tipePesanan = _order!['tipe_pesanan'] ?? 'dine_in';
    final catatan = _order!['catatan_pesanan'];
    final totalHarga = _order!['total_harga'];

    final dynamic rawDetails = _order!['details'];
    final List<dynamic> details = rawDetails is List
        ? rawDetails
        : (rawDetails is Map ? rawDetails.values.toList() : []);

    final payment = _order!['payment'] as Map<String, dynamic>?;
    final ulasan = _order!['ulasan'];
    final createdAt = _order!['created_at'];
    final isActive = _isActiveStatus(status);
    final isSiap =
        (tipePesanan == 'delivery' && status == 'dalam_perjalanan') ||
        (tipePesanan != 'delivery' && status == 'siap_diambil');
    final baseUrl = _getBaseUrl();

    // Progress step
    int activeStep = -1;
    if (status == 'dibayar' || status == 'dikonfirmasi' || status == 'diproses') {
      activeStep = 0;
    } else if (status == 'dimasak') {
      activeStep = 1;
    } else if (status == 'siap_diambil' ||
        status == 'menunggu_dikirim' ||
        status == 'dalam_perjalanan' ||
        status == 'selesai') {
      activeStep = 2;
    }

    // Status badge
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFF2994A);
        statusLabel = 'Pending';
        break;
      case 'menunggu_persetujuan':
        statusColor = const Color(0xFFF2994A);
        statusLabel = 'Menunggu Persetujuan';
        break;
      case 'menunggu_pembayaran':
        statusColor = const Color(0xFFF2994A);
        statusLabel = 'Belum Bayar';
        break;
      case 'dibayar':
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'Dibayar';
        break;
      case 'dikonfirmasi':
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'Dikonfirmasi';
        break;
      case 'diproses':
      case 'dimasak':
        statusColor = const Color(0xFFF2994A);
        statusLabel = status == 'diproses' ? 'Diproses' : 'Dimasak';
        break;
      case 'siap_diambil':
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Siap Diambil';
        break;
      case 'menunggu_dikirim':
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'Menunggu Dikirim';
        break;
      case 'dalam_perjalanan':
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'Dalam Perjalanan';
        break;
      case 'selesai':
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Selesai';
        break;
      case 'ditolak':
        statusColor = const Color(0xFFE53935);
        statusLabel = 'Ditolak';
        break;
      case 'dibatalkan':
        statusColor = const Color(0xFF9E9E9E);
        statusLabel = 'Dibatalkan';
        break;
      case 'gagal':
        statusColor = const Color(0xFFE53935);
        statusLabel = 'Gagal';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6ED),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A2E),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── QR Code Section (At the very top) ──
            if (payment != null &&
                [
                  'sudah_bayar',
                  'sukses',
                  'berhasil',
                ].contains(payment['status_bayar']) &&
                _isActiveStatus(status)) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFE0C2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Konfirmasi Pesanan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: QrImageView(
                          data: 'ORD-${widget.pesananId}',
                          version: QrVersions.auto,
                          size: 140.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tipePesanan == 'delivery'
                          ? 'Tunjukkan QR ini kepada kurir untuk mengonfirmasi pesanan telah diterima'
                          : 'Tunjukkan QR ini kepada penjual untuk mengonfirmasi pesanan telah diterima',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            // ── HEADER SECTION ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE0C2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Kantin info + Status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kantin logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kantinLogo != null
                            ? Image.network(
                                '$baseUrl/storage/$kantinLogo',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildKantinPlaceholder(),
                              )
                            : _buildKantinPlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kantinName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (status == 'ditolak' || status == 'dibatalkan')
                                  ? 'Nomor Antrean'
                                  : (nomorAntrian == '-' ||
                                        status == 'menunggu_persetujuan' ||
                                        status == 'menunggu_pembayaran')
                                  ? 'Antrean: Belum Tersedia'
                                  : 'Antrean: $nomorAntrian',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Progress tracker for active orders
                  if (isActive && activeStep >= 0) ...[
                    const SizedBox(height: 20),
                    _buildProgressTracker(activeStep, tipePesanan),
                  ],

                  if (isSiap) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tipePesanan == 'delivery'
                                ? 'Pesanan siap diantar ke lokasi!'
                                : 'Pesanan siap diambil!',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── DETAIL ITEM SECTION ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE0C2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Item',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...details.map((item) => _buildItemRow(item, baseUrl)),
                ],
              ),
            ),

            // ── RINGKASAN PEMBAYARAN ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE0C2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (payment != null) ...[
                    _buildInfoRow(
                      'Metode Bayar',
                      payment['metode_bayar'] ?? '-',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Status Bayar',
                      payment['status_bayar'] ?? '-',
                    ),
                    const SizedBox(height: 8),
                  ],
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(totalHarga)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3A8C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── INFO PESANAN ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE0C2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Info Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Tipe Pesanan',
                    _getOrderTypeConfig(tipePesanan)['label'],
                  ),
                  if (catatan != null && catatan.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Catatan', catatan.toString()),
                  ],
                  const SizedBox(height: 8),
                  _buildInfoRow('Waktu Pesan', _formatDate(createdAt)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── ULASAN SECTION ──
            if (ulasan != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFE0C2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ulasan Anda',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (ulasan['rating'] ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF2994A),
                          size: 24,
                        );
                      }),
                    ),
                    if (ulasan['komentar'] != null &&
                        ulasan['komentar'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ulasan['komentar'].toString().trim(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildProgressTracker(int activeStep, String tipePesanan) {
    final steps = tipePesanan == 'delivery'
        ? ['Diterima', 'Disiapkan', 'Dikirim']
        : ['Diterima', 'Dimasak', 'Siap Diambil'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = index ~/ 2;
          final isActive = activeStep > stepBefore;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        } else {
          final stepIndex = index ~/ 2;
          final isActive = activeStep >= stepIndex;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isActive ? Icons.check : Icons.circle,
                  color: isActive ? Colors.white : Colors.grey.shade400,
                  size: isActive ? 18 : 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildItemRow(dynamic item, String baseUrl) {
    final name = item['nama_item'] ?? '-';
    final photo = item['foto_menu'];
    final qty = item['jumlah_pesanan'] ?? 1;
    final harga = item['harga_saat_beli'] ?? 0;
    final subtotal = item['subtotal'] ?? 0;
    final dynamic rawVarian = item['varian_snapshot'];
    final List<dynamic>? varian = rawVarian is List
        ? rawVarian
        : (rawVarian is Map ? rawVarian.values.toList() : null);

    final dynamic rawTopping = item['topping_snapshot'];
    final List<dynamic>? topping = rawTopping is List
        ? rawTopping
        : (rawTopping is Map ? rawTopping.values.toList() : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu photo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: photo != null
                ? Image.network(
                    '$baseUrl/storage/$photo',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildSmallPlaceholder(),
                  )
                : _buildSmallPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$qty × Rp ${_formatCurrency(harga)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                // Varian
                if (varian != null && varian.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...varian.map((v) {
                    final vName = v is Map
                        ? (v['nama'] ?? v['name'] ?? v.toString())
                        : v.toString();
                    return Text(
                      '• Varian: $vName',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    );
                  }),
                ],
                // Topping
                if (topping != null && topping.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ...topping.map((t) {
                    final tName = t is Map
                        ? (t['nama'] ?? t['name'] ?? t.toString())
                        : t.toString();
                    return Text(
                      '• Topping: $tName',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rp ${_formatCurrency(subtotal)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildKantinPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.storefront, color: Colors.grey.shade400, size: 22),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 24),
    );
  }
}
