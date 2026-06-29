import 'dart:async';
import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../services/order_service.dart';
import '../widgets/delivery_tracking_card.dart';
import '../../../tracking/widgets/location_permission_sheet.dart';
import '../../scanner/screens/qr_scanner_screen.dart';
import 'order_detail_screen.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

// ==========================================
// ORDER LIST SCREEN (TERHUBUNG API)
// ==========================================
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  int _selectedTabIndex = 0;
  bool _isBuka = true;
  String _namaKantin = 'Memuat...';

  // Instance API Service
  final OrderService _orderService = OrderService();

  // State Data & Loading
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _userRole = 'pegawai';
  String _selectedTypeFilter = 'all';
  Timer? _pollingTimer;

  Color get _primaryColor => _userRole == 'pegawai'
      ? const Color(0xFF5E7AC4)
      : const Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchOrders(showLoading: true); // Ambil data saat layar pertama kali dibuka
    _checkLocationPermission();

    // Auto-refresh di background setiap 10 detik agar pesanan masuk langsung ter-update
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchOrders(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        final granted = await showLocationPermissionSheet(context);
        if (granted == true) {
          await Geolocator.requestPermission();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRole() async {
    final prefs = EncryptedSharedPreferences();
    final role = await prefs.getString('user_role');
    if (!mounted) return;
    setState(() {
      _userRole = role.isNotEmpty ? role : 'pegawai';
    });
  }

  // --- FUNGSI AMBIL DATA API ---
  Future<void> _fetchOrders({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _orderService
          .getOrders(); // response sekarang berupa Map
      if (mounted) {
        setState(() {
          _orders = response['data'] as List<dynamic>; // Ambil data pesanan

          // Ambil data kantinnya
          if (response['kantin'] != null) {
            _namaKantin = response['kantin']['nama_kantin'] ?? 'Kantin Sipil';
            // Atur posisi awal toggle otomatis sesuai database!
            _isBuka = response['kantin']['status_toko'] == 'buka';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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

  // --- FUNGSI UPDATE STATUS API ---
  Future<void> _updateStatus(
    int orderId,
    String newStatus, {
    String? alasan,
  }) async {
    // Munculkan dialog loading transparan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: AppLoadingAnimation()),
    );

    try {
      await _orderService.updateOrderStatus(
        orderId,
        newStatus,
        alasanPenolakan: alasan,
      );
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        _fetchOrders(showLoading: false); // Refresh data dari server agar antrian & status terbaru muncul
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startDelivery(int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: AppLoadingAnimation()),
    );

    try {
      await _orderService.startDelivery(orderId);
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        _fetchOrders(showLoading: false); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengantaran dimulai!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> currentOrders = _orders.where((order) {
      final status = order['status_pesanan'];
      
      bool matchesTab = false;
      if (_selectedTabIndex == 0) {
        matchesTab = status == 'pending' || status == 'menunggu_persetujuan' || status == 'dibayar' || status == 'menunggu_pembayaran'; // Baru masuk
      } else if (_selectedTabIndex == 1) {
        matchesTab = status == 'dimasak' ||
            status == 'dalam_perjalanan' ||
            status == 'siap_diambil' ||
            status == 'menunggu_dikirim'; // Diproses
      } else {
        matchesTab = status == 'selesai' || status == 'dibatalkan'; // Selesai
      }

      if (!matchesTab) return false;

      // Filter berdasarkan tipe pesanan
      final tipePesanan = (order['tipe_pesanan'] ?? '').toString().toLowerCase();
      if (_selectedTypeFilter == 'all') {
        return true;
      } else if (_selectedTypeFilter == 'dine_in') {
        return tipePesanan.contains('dine in') ||
            tipePesanan.contains('makan di tempat') ||
            tipePesanan.contains('dine_in') ||
            tipePesanan.contains('dine-in');
      } else if (_selectedTypeFilter == 'take_away') {
        return tipePesanan.contains('take away') ||
            tipePesanan.contains('bungkus') ||
            tipePesanan.contains('take_away') ||
            tipePesanan.contains('take-away');
      } else if (_selectedTypeFilter == 'delivery') {
        return tipePesanan.contains('delivery') ||
            tipePesanan.contains('pengantaran');
      }

      return true;
    }).toList();

    double totalPendapatan = _orders
        .where((o) => o['status_pesanan'] == 'selesai')
        .fold(
          0.0,
          (sum, o) =>
              sum +
              (double.tryParse(o['total_harga']?.toString() ?? '0') ?? 0.0),
        );

    int totalSelesai = _orders
        .where((o) => o['status_pesanan'] == 'selesai')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant, color: _primaryColor, size: 20),
          ),
        ),
        title: Text(
          _namaKantin,
          style: const TextStyle(
            // const-nya dipindah ke TextStyle saja
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_userRole == 'pemilik')
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 28,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _isBuka,
                        onChanged: (val) async {
                          // 1. Simpan status lama buat berjaga-jaga
                          bool oldStatus = _isBuka;

                          // 2. Ubah UI langsung (Optimistic Update)
                          setState(() {
                            _isBuka = val;
                          });

                          // 3. Tembak API-nya
                          try {
                            String statusString = val ? 'buka' : 'tutup';
                            await _orderService.updateStatusKantin(
                              statusString,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Kantin sekarang $statusString',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            // 4. Jika gagal, kembalikan posisi toggle ke semula
                            setState(() {
                              _isBuka = oldStatus;
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengubah status: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.greenAccent.shade400,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isBuka ? "BUKA" : "TUTUP",
                    style: TextStyle(
                      color: _isBuka ? Colors.white : Colors.redAccent.shade100,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchOrders(showLoading: false),
        color: _primaryColor,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // HEADER BIRU MELENGKUNG
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Ringkasan Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSummaryCard(
                            Icons.account_balance_wallet,
                            'Pendapatan',
                            'Rp ${NumberFormat('#,###', 'id_ID').format(totalPendapatan)}', // <-- Pakai variabel
                            const Color(0xFFF2994A),
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            Icons.receipt_long,
                            'Total Selesai',
                            '$totalSelesai', // <-- Pakai variabel
                            const Color(0xFFA29BFE),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // TABS MANAJEMEN PESANAN (STICKY HEADER)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  height: 190.0,
                  child: Container(
                    color: const Color(
                      0xFFF4F6FB,
                    ), // Sesuai warna background Scaffold
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manajemen Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTab(
                                0,
                                'Baru Masuk',
                                badgeCount: _orders
                                  .where(
                                    (o) =>
                                        o['status_pesanan'] == 'dibayar' ||
                                        o['status_pesanan'] == 'pending' ||
                                        o['status_pesanan'] == 'menunggu_persetujuan' ||
                                        o['status_pesanan'] == 'menunggu_pembayaran',
                                  )
                                  .length,
                              ),
                              const SizedBox(width: 8),
                              _buildTab(
                                1,
                                'Diproses',
                                badgeCount: _orders
                                    .where(
                                      (o) =>
                                          o['status_pesanan'] == 'dimasak' ||
                                          o['status_pesanan'] == 'dalam_perjalanan' ||
                                          o['status_pesanan'] == 'siap_diambil' ||
                                          o['status_pesanan'] == 'menunggu_dikirim',
                                    )
                                    .length,
                              ),
                              const SizedBox(width: 8),
                              _buildTab(
                                2,
                                'Selesai',
                                badgeCount: _orders
                                    .where(
                                      (o) => o['status_pesanan'] == 'selesai' ||
                                             o['status_pesanan'] == 'dibatalkan',
                                    )
                                    .length,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTypeFilterChip('Semua', 'all'),
                              const SizedBox(width: 8),
                              _buildTypeFilterChip('Makan di Tempat', 'dine_in'),
                              const SizedBox(width: 8),
                              _buildTypeFilterChip('Bungkus', 'take_away'),
                              const SizedBox(width: 8),
                              _buildTypeFilterChip('Pengantaran', 'delivery'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(child: AppLoadingAnimation()),
                    ),
                  ],
                )
              : currentOrders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedTabIndex == 0
                                      ? 'Tidak ada pesanan masuk'
                                      : _selectedTabIndex == 1
                                          ? 'Tidak ada pesanan diproses'
                                          : 'Tidak ada pesanan selesai',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 0,
                        bottom: 20,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: currentOrders.length,
                      itemBuilder: (context, index) {
                        final orderMap =
                            currentOrders[index] as Map<String, dynamic>;
                        final status = orderMap['status_pesanan'];
                        final orderId = orderMap['id'];

                        if (status == 'selesai' || status == 'dibatalkan') {
                          return CompletedOrderCard(
                            key: ValueKey(orderId),
                            order: orderMap,
                            primaryColor: _primaryColor,
                          );
                        }

                        if (status == 'dalam_perjalanan') {
                          return DeliveryTrackingCard(
                            key: ValueKey(orderId),
                            order: orderMap,
                            primaryColor: _primaryColor,
                            onScanQr: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const QrScannerScreen(),
                                ),
                              ).then((_) => _fetchOrders());
                            },
                          );
                        }

                        return OrderCard(
                          key: ValueKey(orderId),
                          order: orderMap,
                          primaryColor: _primaryColor,
                          tabIndex: _selectedTabIndex,
                          onTerima: () {
                            if (status == 'pending' || status == 'menunggu_persetujuan') {
                              _updateStatus(orderId, 'menunggu_pembayaran');
                            } else {
                              _updateStatus(orderId, 'dimasak');
                            }
                          },
                          onTolak: () {
                            showDialog(
                              context: context,
                              builder: (context) => RejectOrderDialog(
                                onReject: (alasan) => _updateStatus(
                                  orderId,
                                  'ditolak',
                                  alasan: alasan,
                                ),
                              ),
                            );
                          },
                          onSelesaiMasak: () {
                            final tipe = orderMap['tipe_pesanan'] ?? '';
                            if (tipe.toLowerCase().contains('pengantaran') ||
                                tipe.toLowerCase().contains('delivery')) {
                              _updateStatus(orderId, 'menunggu_dikirim');
                            } else {
                              _updateStatus(orderId, 'siap_diambil');
                            }
                          },
                          onKirimPesanan: () => _startDelivery(orderId),
                          onScanQr: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QrScannerScreen(),
                              ),
                            ).then((_) => _fetchOrders());
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }

  // --- Widget Bantuan Tabs & Summary ---
  Widget _buildSummaryCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF828282)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title, {int badgeCount = 0}) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        // Kunci minWidth agar ukuran tab stabil meski badge hilang/muncul
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Pusatkan teks & badge di dalam tab
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4F4F4F),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (badgeCount > 0 && !isSelected) ...[
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 10,
                backgroundColor: _primaryColor.withValues(alpha: 0.1),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, String type) {
    bool isSelected = _selectedTypeFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTypeFilter = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4F4F4F),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// DELEGATE UNTUK STICKY HEADER (TABS)
// ==========================================
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyTabBarDelegate({required this.child, this.height = 120.0});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

// ==========================================
// WIDGET COMPLETED ORDER
// ==========================================
class CompletedOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryColor;

  const CompletedOrderCard({
    super.key,
    required this.order,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> details = order['details'] ?? [];
    String displayItems = details
        .take(2)
        .map((item) => item['menu']?['nama_item']?.toString() ?? '')
        .join(' + ');
    bool hasMore = details.length > 2;
    String waktuUpdate = order['updated_at'] != null
        ? DateFormat(
            'HH:mm',
          ).format(DateTime.parse(order['updated_at']).toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => OrderDetailsDialog(
                order: order,
                primaryColor: primaryColor,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9EA3B0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          order['nomor_antrian'] ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayItems,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasMore) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '(...)',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            order['status_pesanan'] == 'selesai'
                                ? Icons.check
                                : Icons.close,
                            color: order['status_pesanan'] == 'selesai'
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFE53935),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order['status_pesanan'] == 'selesai'
                                ? 'Selesai'
                                : (order['status_pesanan'] == 'ditolak'
                                    ? 'Ditolak'
                                    : 'Dibatalkan'),
                            style: TextStyle(
                              color: order['status_pesanan'] == 'selesai'
                                  ? const Color(0xFF27AE60)
                                  : const Color(0xFFE53935),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            waktuUpdate,
                            style: const TextStyle(
                              color: Color(0xFF828282),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format((double.tryParse(order['total_harga'].toString()) ?? 0).toInt())}',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET ORDER CARD
// ==========================================
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int tabIndex;
  final VoidCallback onTerima;
  final VoidCallback onTolak;
  final VoidCallback onSelesaiMasak;
  final VoidCallback? onKirimPesanan;
  final VoidCallback? onScanQr;
  final Color primaryColor;

  const OrderCard({
    super.key,
    required this.order,
    required this.tabIndex,
    required this.onTerima,
    required this.onTolak,
    required this.onSelesaiMasak,
    this.onKirimPesanan,
    this.onScanQr,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> details = order['details'] ?? [];
    String namaPemesan = order['mahasiswa']?['nama_mahasiswa'] ?? 'Tanpa Nama';
    String catatan = order['catatan_pesanan'] ?? '';
    String tipePesanan = order['tipe_pesanan'] ?? '-';

    // Tentukan warna tag berdasarkan tipe pesanan
    Color tipeColor = Colors.grey;
    Color tipeBgColor = Colors.grey.shade100;
    if (tipePesanan.toLowerCase().contains('dine in') ||
        tipePesanan.toLowerCase().contains('makan di tempat') ||
        tipePesanan.toLowerCase().contains('dine_in') ||
        tipePesanan.toLowerCase().contains('dine-in')) {
      tipeColor = const Color(0xFF27AE60);
      tipeBgColor = const Color(0xFFB9F6CA).withValues(alpha: 0.5);
    } else if (tipePesanan.toLowerCase().contains('take away') ||
        tipePesanan.toLowerCase().contains('bungkus') ||
        tipePesanan.toLowerCase().contains('take_away') ||
        tipePesanan.toLowerCase().contains('take-away')) {
      tipeColor = const Color(0xFFF2994A);
      tipeBgColor = const Color(0xFFFFF3F0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD (Sama seperti DeliveryTrackingCard)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
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
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                        order['nomor_antrian'] ?? '-',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (order['status_pesanan'] == 'dimasak') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB9F6CA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Dimasak',
                          style: TextStyle(
                            color: Color(0xFF27AE60),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (order['status_pesanan'] == 'menunggu_pembayaran') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Belum Bayar',
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipe Pesanan
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tipeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tipePesanan.toUpperCase(),
                        style: TextStyle(
                          color: tipeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // KOTAK ITEM PESANAN (Persis seperti DeliveryTrackingCard)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: details.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item['jumlah_pesanan'] ?? 1}x',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['menu']?['nama_item'] ?? 'Item',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // KOTAK CATATAN
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFFF2994A),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan Pembeli',
                                style: TextStyle(
                                  color: Color(0xFFF2994A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '"$catatan"',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // TOTAL HARGA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF828282),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format((double.tryParse(order['total_harga'].toString()) ?? 0).toInt())}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (tabIndex == 0 && (order['status_pesanan'] == 'pending' || order['status_pesanan'] == 'menunggu_persetujuan')) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTolak,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF2994A)),
                            foregroundColor: const Color(0xFFF2994A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tolak',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onTerima,
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
                            'Terima',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                              order: order,
                              primaryColor: primaryColor,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Detail Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ] else if (tabIndex == 1 &&
                    order['status_pesanan'] == 'dimasak') ...[
                  // 1. Tambahkan Tombol Lihat Detail Pesanan (Warna Biru)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                              order: order,
                              primaryColor: primaryColor,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Detail Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Jarak antar tombol
                  // 2. Tombol Selesai Masak (Warna Orange)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelesaiMasak,
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
                        'Selesai Masak',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ] else if (tabIndex == 0 &&
                    order['status_pesanan'] == 'dibayar') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                              order: order,
                              primaryColor: primaryColor,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Detail Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTerima,
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
                        'Mulai Masak',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ] else if (tabIndex == 0 &&
                    order['status_pesanan'] == 'menunggu_pembayaran') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                              order: order,
                              primaryColor: primaryColor,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Detail Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Menunggu pembayaran dari mahasiswa.',
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (tabIndex == 1 &&
                    order['status_pesanan'] == 'menunggu_dikirim') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onKirimPesanan,
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
                        'Kirim Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ] else if (tabIndex == 1 &&
                    order['status_pesanan'] == 'siap_diambil') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onScanQr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2994A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Scan QR',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET DELIVERY TRACKING
// ==========================================
class RejectOrderDialog extends StatefulWidget {
  final Function(String) onReject;
  const RejectOrderDialog({super.key, required this.onReject});

  @override
  State<RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<RejectOrderDialog> {
  String _selectedOption = 'Stok bahan habis';
  final TextEditingController _customReasonController = TextEditingController();

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tolak Pesanan?',
                style: TextStyle(
                  color: Color(0xFFF2994A),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pilih atau tulis alasan penolakan agar pembeli mengetahui kendala Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4F4F4F),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _buildRadio('Stok bahan habis'),
              _buildRadio('Kantin sedang terlalu ramai'),
              _buildRadio('Menu tidak tersedia hari ini'),
              _buildRadio('Lainnya'),

              if (_selectedOption == 'Lainnya') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customReasonController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tulis alasan penolakan...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFF2994A),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFF2994A),
                          width: 1.5,
                        ),
                        foregroundColor: const Color(0xFFF2994A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        String reason = _selectedOption == 'Lainnya'
                            ? _customReasonController.text
                            : _selectedOption;
                        Navigator.pop(context);
                        widget.onReject(reason);
                      },
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
                        'Tolak',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(String title) {
    return InkWell(
      onTap: () => setState(() => _selectedOption = title),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              _selectedOption == title
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedOption == title
                  ? const Color(0xFFF2994A)
                  : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET DETAIL ORDER DIALOG (PREMIUM)
// ==========================================
class OrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryColor;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final details = order['details'] as List<dynamic>? ?? [];
    final studentName = order['mahasiswa']?['nama_mahasiswa'] ?? 'Tanpa Nama';
    final notes = order['catatan_pesanan'] ?? '';
    final orderType = order['tipe_pesanan'] ?? '-';

    // Format order time
    String orderTime = '-';
    if (order['created_at'] != null) {
      try {
        final dt = DateTime.parse(order['created_at']).toLocal();
        orderTime = '${DateFormat('HH:mm').format(dt)} WIB';
      } catch (_) {}
    }

    final totalHarga = (double.tryParse(order['total_harga']?.toString() ?? '0') ?? 0).toInt();

    // Calculate subtotal dynamically
    int subtotal = 0;
    for (var item in details) {
      subtotal += (double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0).toInt();
    }
    final additionalFee = totalHarga - subtotal;

    // Payment details
    final payment = order['payment'] ?? {};
    final paymentMethod = payment['metode_bayar']?.toString().toUpperCase() ?? 'QRIS';
    final rawStatus = payment['status_bayar']?.toString().toLowerCase() ?? '';
    final paymentStatus = (rawStatus == 'sukses' || rawStatus == 'berhasil') ? 'LUNAS' : rawStatus.toUpperCase();

    // Map order type colors
    Color typeColor = Colors.grey;
    Color typeBgColor = Colors.grey.shade100;
    if (orderType.toLowerCase().contains('dine in') || orderType.toLowerCase().contains('makan di tempat')) {
      typeColor = const Color(0xFF27AE60);
      typeBgColor = const Color(0xFFE8F5E9);
    } else if (orderType.toLowerCase().contains('take away') || orderType.toLowerCase().contains('bungkus')) {
      typeColor = const Color(0xFFF2994A);
      typeBgColor = const Color(0xFFFFF3F0);
    } else if (orderType.toLowerCase().contains('delivery') || orderType.toLowerCase().contains('pengantaran')) {
      typeColor = const Color(0xFF2F80ED);
      typeBgColor = const Color(0xFFE3F2FD);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrian ${order['nomor_antrian'] ?? '-'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#ORD-${order['id'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.grey, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFECEFF1)),

            // --- SCROLLABLE CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- INFO UTAMA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tipe Pesanan Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            orderType.toUpperCase(),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Payment Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paymentStatus.isNotEmpty ? paymentStatus : 'LUNAS',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Detail Customer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          Text(
                            orderTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- ITEMS LIST ---
                    const Text(
                      'Rincian Pesanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(details.length, (idx) {
                      final item = details[idx];
                      final namaMenu = item['menu']?['nama_item'] ?? 'Item';
                      final qty = int.tryParse(item['jumlah_pesanan']?.toString() ?? '1') ?? 1;
                      final hargaSatuan = (double.tryParse(item['harga_saat_beli']?.toString() ?? '0') ?? 0).toInt();
                      final dynamic rawVarian = item['varian_snapshot'];
                      final List<Map<String, String>> parsedVariants = [];

                      if (rawVarian != null) {
                        if (rawVarian is Map) {
                          rawVarian.forEach((key, value) {
                            final category = key.toString();
                            if (value is Map) {
                              final nama = value['nama'] ?? value['name'] ?? '-';
                              parsedVariants.add({
                                'category': category,
                                'name': nama.toString(),
                              });
                            } else if (value is List) {
                              for (var v in value) {
                                if (v is Map) {
                                  final nama = v['nama'] ?? v['name'] ?? '-';
                                  parsedVariants.add({
                                    'category': category,
                                    'name': nama.toString(),
                                  });
                                } else {
                                  parsedVariants.add({
                                    'category': category,
                                    'name': v.toString(),
                                  });
                                }
                              }
                            } else {
                              parsedVariants.add({
                                'category': category,
                                'name': value.toString(),
                              });
                            }
                          });
                        } else if (rawVarian is List) {
                          for (var v in rawVarian) {
                            if (v is Map) {
                              final nama = v['nama'] ?? v['name'] ?? v.toString();
                              parsedVariants.add({
                                'category': 'Varian',
                                'name': nama.toString(),
                              });
                            } else {
                              parsedVariants.add({
                                'category': 'Varian',
                                'name': v.toString(),
                              });
                            }
                          }
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6FB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${qty}x',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    namaMenu,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  if (parsedVariants.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    ...parsedVariants.map(
                                      (v) => Text(
                                        '• ${v['category']}: ${v['name']}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(hargaSatuan * qty)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),

                    // --- CATATAN ---
                    if (notes.toString().isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF2994A).withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.chat_bubble_outline, color: Color(0xFFF2994A), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Catatan: "$notes"',
                                style: const TextStyle(
                                  color: Color(0xFFF2994A),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 16),

                    // --- RINCIAN BIAYA ---
                    _summaryRow('Subtotal', subtotal),
                    if (additionalFee > 0) ...[
                      const SizedBox(height: 8),
                      _summaryRow('Biaya Lainnya', additionalFee),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          paymentMethod,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFECEFF1)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- ACTION BUTTON ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(
                              order: order,
                              primaryColor: primaryColor,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Halaman Detail',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Text(
          'Rp ${NumberFormat('#,###', 'id_ID').format(price)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
