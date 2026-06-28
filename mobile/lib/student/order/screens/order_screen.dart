import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../student/tracking/screens/live_tracking_screen.dart';
import 'order_detail_screen.dart';
import '../widgets/review_popup.dart';
import '../../payment/screens/payment_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;
  Timer? _pollingTimer;

  bool _isLoading = true;
  List<dynamic> _dalamProses = [];
  List<dynamic> _riwayat = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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

    _fetchOrders(showLoading: true);

    // Auto-refresh di background setiap 10 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchOrders(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _fetchOrders({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _dio.get(
        '/mahasiswa/orders',
        options: await _authOptions(),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _dalamProses = data['dalam_proses'] ?? [];
            _riwayat = data['riwayat'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Jangan tampilkan notifikasi error jika ini hanya polling background
        if (showLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat pesanan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelOrder(int orderId) async {
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
      final token = await _prefs.getString('auth_token');
      final response = await _dio.patch(
        '/mahasiswa/orders/$orderId/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil dibatalkan'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan pesanan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _fetchOrders(showLoading: true);
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
      return DateFormat('d MMMM yyyy HH.mm', 'id_ID').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _getBaseUrl() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    // Remove /api suffix to get base storage URL
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFF6ED),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0C2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF9FA5C0),
              indicator: BoxDecoration(
                color: const Color(0xFFF2994A),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Dalam Proses'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D3A8C)),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildDalamProsesTab(), _buildRiwayatTab()],
            ),
    );
  }

  // ==========================================
  // TAB 1: DALAM PROSES
  // ==========================================
  Widget _buildDalamProsesTab() {
    if (_dalamProses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchOrders(showLoading: false),
        color: const Color(0xFF2D3A8C),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Tidak ada pesanan aktif',
                subtitle: 'Pesanan aktif Anda akan muncul di sini',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchOrders(showLoading: false),
      color: const Color(0xFF2D3A8C),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _dalamProses.length,
        itemBuilder: (context, index) {
          final order = _dalamProses[index] as Map<String, dynamic>;
          return _buildActiveOrderCard(order);
        },
      ),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final status = order['status_pesanan'] ?? '';
    final nomorAntrian = order['nomor_antrian'] ?? '-';
    final orderId = order['id'];
    final totalHarga = order['total_harga'];
    final tipePesanan = order['tipe_pesanan'] ?? 'dine_in';
    final dynamic rawDetails = order['details'];
    final List<dynamic> details = rawDetails is List
        ? rawDetails
        : (rawDetails is Map ? rawDetails.values.toList() : []);

    // Build item names string
    final itemNames = details
        .map((d) => d['menu']?['nama_item'] ?? '')
        .where((n) => n.isNotEmpty)
        .join(' + ');
    final itemCount = details.length;

    // Progress steps
    int activeStep = 0;
    if (status == 'dibayar') activeStep = 0;
    if (status == 'dikonfirmasi' || status == 'diproses') activeStep = 1;
    if (status == 'dimasak') activeStep = 2;

    if (tipePesanan == 'delivery') {
      if (status == 'menunggu_dikirim') activeStep = 2;
      if (status == 'dalam_perjalanan') activeStep = 3;
    } else {
      if (status == 'siap_diambil') activeStep = 3;
    }

    final bool isSiap =
        (tipePesanan == 'delivery' && status == 'dalam_perjalanan') ||
        (tipePesanan != 'delivery' && status == 'siap_diambil');

    final bool isPrePayment = status == 'pending' || 
                              status == 'menunggu_persetujuan' || 
                              status == 'menunggu_pembayaran';

    String headerLabel = 'Nomor Antrean';
    String headerVal = nomorAntrian;
    if (status == 'pending') {
      headerLabel = 'Status Pesanan';
      headerVal = 'Belum Diajukan';
    } else if (status == 'menunggu_persetujuan') {
      headerLabel = 'Status Pesanan';
      headerVal = 'Persetujuan';
    } else if (status == 'menunggu_pembayaran') {
      headerLabel = 'Status Pesanan';
      headerVal = 'Belum Dibayar';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0C2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF08D39).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF08D39), Color(0xFFE56A21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          headerVal,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getOrderTypeConfig(
                              tipePesanan,
                            )['color'].withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getOrderTypeConfig(tipePesanan)['icon'],
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getOrderTypeConfig(tipePesanan)['label'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Progress Tracker ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: isPrePayment
                ? _buildPrePaymentBanner(status)
                : _buildProgressTracker(activeStep, tipePesanan),
          ),

          // ── Order Details ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemNames,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$itemCount item pesanan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rp ${_formatCurrency(totalHarga)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          // ── Siap Diambil Banner ──
          if (isSiap)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
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
                    Expanded(
                      child: Text(
                        tipePesanan == 'delivery'
                            ? 'Pesanan Anda sedang diantar ke lokasi!'
                            : 'Pesanan Anda sudah siap diambil!',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Action Buttons ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (status == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              pesananId: orderId,
                              totalHarga: double.tryParse(totalHarga.toString()) ?? 0.0,
                            ),
                          ),
                        ).then((_) => _fetchOrders());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3A8C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Pesan Sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(orderId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batalkan Pesanan',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (status == 'menunggu_persetujuan') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              pesananId: orderId,
                              totalHarga: double.tryParse(totalHarga.toString()) ?? 0.0,
                            ),
                          ),
                        ).then((_) => _fetchOrders());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3A8C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Pantau Persetujuan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(orderId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batalkan Pesanan',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (status == 'menunggu_pembayaran') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              pesananId: orderId,
                              totalHarga: double.tryParse(totalHarga.toString()) ?? 0.0,
                            ),
                          ),
                        ).then((_) => _fetchOrders());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Bayar Sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (tipePesanan == 'delivery' &&
                    status == 'dalam_perjalanan') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveTrackingScreen(
                              pesananId: orderId.toString(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3A8C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lacak Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(pesananId: orderId),
                        ),
                      ).then((_) => _fetchOrders());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF08D39),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lihat Detail Pesanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(int activeStep, String tipePesanan) {
    final steps = tipePesanan == 'delivery'
        ? ['Diterima', 'Disiapkan', 'Dikirim']
        : ['Diterima', 'Dimasak', 'Siap Diambil'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
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
          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = activeStep > stepIndex;
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

  // ==========================================
  // TAB 2: RIWAYAT
  // ==========================================
  Widget _buildRiwayatTab() {
    if (_riwayat.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchOrders(showLoading: false),
        color: const Color(0xFF2D3A8C),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(
                icon: Icons.history,
                title: 'Belum ada riwayat pesanan',
                subtitle: 'Riwayat pesanan Anda akan muncul di sini',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchOrders(showLoading: false),
      color: const Color(0xFF2D3A8C),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(_riwayat.length, (index) {
            final order = _riwayat[index] as Map<String, dynamic>;
            return _buildHistoryCard(order);
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final status = order['status_pesanan'] ?? '';
    final nomorAntrian = order['nomor_antrian'] ?? '-';
    final orderId = order['id'];
    final totalHarga = order['total_harga'];
    final createdAt = order['created_at'];
    final dynamic rawDetails = order['details'];
    final List<dynamic> details = rawDetails is List
        ? rawDetails
        : (rawDetails is Map ? rawDetails.values.toList() : []);
    final kantin = order['kantin'] as Map<String, dynamic>?;
    final ulasan = order['ulasan'];

    // First item info
    final firstDetail = details.isNotEmpty ? details[0] : null;
    final firstItemName = firstDetail?['menu']?['nama_item'] ?? 'Pesanan';
    final firstItemPhoto = firstDetail?['menu']?['foto_menu'];
    final kantinName = kantin?['nama_kantin'] ?? '-';

    // Status badge config
    Color statusColor;
    String statusLabel;
    switch (status) {
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

    final baseUrl = _getBaseUrl();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0C2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF08D39).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Gradient) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF08D39), Color(0xFFE56A21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (status == 'ditolak' || status == 'dibatalkan')
                              ? 'Nomor Antrean'
                              : 'Nomor Antrean',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (status == 'ditolak' || status == 'dibatalkan')
                              ? '-'
                              : nomorAntrian,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getOrderTypeConfig(
                              order['tipe_pesanan'] ?? 'dine_in',
                            )['color'].withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getOrderTypeConfig(
                                  order['tipe_pesanan'] ?? 'dine_in',
                                )['icon'],
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getOrderTypeConfig(
                                  order['tipe_pesanan'] ?? 'dine_in',
                                )['label'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Item Name + Divider ──
                Text(
                  firstItemName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // ── Content Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: firstItemPhoto != null
                          ? Image.network(
                              '$baseUrl/storage/$firstItemPhoto',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    const SizedBox(width: 12),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kantinName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rp ${_formatCurrency(totalHarga)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Star Rating Display (for reviewed orders) ──
                if (status == 'selesai' && ulasan != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF08D39).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.rate_review_rounded,
                          color: Color(0xFFF08D39),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ulasan Anda',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final ratingValue =
                                (ulasan is Map ? ulasan['rating'] : null) ?? 0;
                            return Icon(
                              index < ratingValue
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: index < ratingValue
                                  ? const Color(0xFFF08D39)
                                  : Colors.grey.shade300,
                              size: 22,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                // ── Nilai Button (for unreviewed orders) ──
                if (status == 'selesai' && ulasan == null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        ReviewPopup.show(
                          context,
                          pesananId: orderId,
                          onReviewSubmitted: () {
                            _fetchOrders();
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF08D39),
                        side: const BorderSide(color: Color(0xFFF08D39)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Nilai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                // Lihat Detail
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(pesananId: orderId),
                        ),
                      ).then((_) => _fetchOrders());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF08D39),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lihat Detail Pesanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrePaymentBanner(String status) {
    String descText = '';
    IconData bannerIcon = Icons.info_outline;
    Color bannerBg = Colors.grey.shade100;
    Color bannerTextCol = Colors.grey.shade700;

    if (status == 'pending') {
      descText = 'Pesanan belum diajukan. Silakan klik "Pesan Sekarang" di bawah ini.';
      bannerIcon = Icons.shopping_cart_checkout;
      bannerBg = const Color(0xFFFFF3E0);
      bannerTextCol = const Color(0xFFE65100);
    } else if (status == 'menunggu_persetujuan') {
      descText = 'Menunggu penjual menyetujui ketersediaan menu Anda.';
      bannerIcon = Icons.hourglass_empty;
      bannerBg = const Color(0xFFE3F2FD);
      bannerTextCol = const Color(0xFF0D47A1);
    } else if (status == 'menunggu_pembayaran') {
      descText = 'Penjual menyetujui pesanan Anda! Silakan lakukan pembayaran.';
      bannerIcon = Icons.qr_code_2;
      bannerBg = const Color(0xFFE8F5E9);
      bannerTextCol = const Color(0xFF1B5E20);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerTextCol, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              descText,
              style: TextStyle(
                color: bannerTextCol,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED WIDGETS
  // ==========================================
  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 28),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
