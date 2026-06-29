import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/finance_service.dart';
import 'seller_order_history_screen.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({Key? key}) : super(key: key);

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  String _selectedFilter = 'Hari Ini';
  final List<String> _filters = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().fetchFinanceData();
    });
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final history = provider.history;

    // --- LOGIKA FILTERING ---
    final DateTime now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    final List<dynamic> filteredOrders = history.where((order) {
      if (order['updated_at'] == null) return false;
      final date = DateTime.parse(order['updated_at']).toLocal();
      
      switch (_selectedFilter) {
        case 'Hari Ini':
          return DateFormat('yyyy-MM-dd').format(date) == todayStr;
        case 'Minggu Ini':
          final difference = now.difference(date).inDays;
          return difference <= 7;
        case 'Bulan Ini':
          return date.year == now.year && date.month == now.month;
        case 'Semua':
        default:
          return true;
      }
    }).toList();

    // 1. Total Pendapatan
    double totalPendapatan = 0;
    for (var order in filteredOrders) {
      totalPendapatan += double.tryParse(order['total_harga']?.toString() ?? '0') ?? 0.0;
    }

    // 2. Total Pesanan
    int totalPesanan = filteredOrders.length;

    // 3. Menu Paling Laris
    final Map<String, Map<String, dynamic>> menuMap = {};
    int totalQtySold = 0;
    for (var order in filteredOrders) {
      final List<dynamic> details = order['details'] ?? [];
      for (var detail in details) {
        final menu = detail['menu'];
        if (menu != null) {
          final String menuName = menu['nama_menu'] ?? 'Menu Lain';
          final String category = (menu['kategori'] ?? 'makanan').toString().toLowerCase();
          final int qty = detail['jumlah_pesanan'] ?? 1;
          
          totalQtySold += qty;
          if (menuMap.containsKey(menuName)) {
            menuMap[menuName]!['qty'] = (menuMap[menuName]!['qty'] as int) + qty;
          } else {
            menuMap[menuName] = {
              'name': menuName,
              'category': category,
              'qty': qty,
            };
          }
        }
      }
    }

    // Urutkan berdasarkan kuantitas terlaris
    final sortedMenus = menuMap.values.toList()
      ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    final topMenus = sortedMenus.take(3).toList();

    // 4. Waktu Rata-rata
    double averageMinutes = 0.0;
    int ordersWithDuration = 0;
    double totalMinutes = 0.0;
    for (var order in filteredOrders) {
      if (order['created_at'] != null && order['updated_at'] != null) {
        final start = DateTime.parse(order['created_at']);
        final end = DateTime.parse(order['updated_at']);
        final diff = end.difference(start).inMinutes;
        if (diff > 0) {
          totalMinutes += diff;
          ordersWithDuration++;
        }
      }
    }
    if (ordersWithDuration > 0) {
      averageMinutes = totalMinutes / ordersWithDuration;
    } else {
      averageMinutes = 15.0; // default fallback
    }

    String formattedAverageTime = '';
    if (averageMinutes >= 60) {
      final hours = (averageMinutes / 60).toStringAsFixed(1);
      formattedAverageTime = '$hours jam';
    } else {
      formattedAverageTime = '${averageMinutes.round()} mnt';
    }

    // 5. Rating Rata-rata
    double totalRating = 0.0;
    int ratedOrdersCount = 0;
    for (var order in filteredOrders) {
      final ulasan = order['ulasan'];
      if (ulasan != null && ulasan['rating'] != null) {
        totalRating += double.tryParse(ulasan['rating'].toString()) ?? 0.0;
        ratedOrdersCount++;
      }
    }
    double averageRating = ratedOrdersCount > 0 ? (totalRating / ratedOrdersCount) : 4.8;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: provider.isLoading
          ? const Center(child: AppLoadingAnimation())
          : RefreshIndicator(
              onRefresh: () => provider.fetchFinanceData(),
              color: const Color(0xFF3F51B5),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  // --- HEADER BIRU MELENGKUNG (FIGMA STYLE) ---
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F51B5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 32,
                      top: MediaQuery.of(context).padding.top + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title, Subtitle & Dropdown Filter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Laporan Keuangan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pantau performa penjualan Anda',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Dropdown Filter
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFilter,
                                  dropdownColor: const Color(0xFF3F51B5),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  items: _filters.map((filter) {
                                    return DropdownMenuItem<String>(
                                      value: filter,
                                      child: Text(filter),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedFilter = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Dua Kartu Pendapatan & Jumlah Pesanan
                        Row(
                          children: [
                            // Total Pendapatan
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.account_balance_wallet, color: Color(0xFFF2994A), size: 16),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Total Pendapatan',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatCurrency(totalPendapatan),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // Total Pesanan
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.assignment, color: Color(0xFF3F51B5), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Total Pesanan',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      totalPesanan.toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // --- AREA CONTENT UTAMA ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Menu Paling Laris
                        const Text(
                          'Menu Paling Laris',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (topMenus.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada data penjualan menu',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        else
                          ...List.generate(topMenus.length, (idx) {
                            final item = topMenus[idx];
                            final String name = item['name'];
                            final String category = item['category'];
                            final int qty = item['qty'];
                            
                            // Hitung persentase
                            final double pct = totalQtySold > 0 ? (qty / totalQtySold * 100) : 0.0;
                            
                            // Warna progress bar
                            Color progressColor = const Color(0xFFF2994A);
                            if (idx == 1) progressColor = const Color(0xFF2F80ED);
                            if (idx == 2) progressColor = const Color(0xFF27AE60);
                            
                            return _buildBestSellingMenuItem(
                              name: name,
                              category: category,
                              quantity: qty,
                              percentage: pct,
                              color: progressColor,
                            );
                          }),
                        
                        const SizedBox(height: 24),
                        
                        // Dua Kartu: Waktu & Rating Rata-rata
                        Row(
                          children: [
                            // Card Waktu Rata-rata
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.access_time_filled, color: Color(0xFF3F51B5), size: 24),
                                    const SizedBox(height: 10),
                                    Text(
                                      formattedAverageTime,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Waktu Rata-rata',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // Card Rating Rata-rata
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFF2C94C), size: 24),
                                    const SizedBox(height: 10),
                                    Text(
                                      averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Rating Rata-rata',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Button Orange di bawah
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: context.read<FinanceProvider>(),
                                    child: const SellerOrderHistoryScreen(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2994A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Lihat Riwayat Pesanan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _buildBestSellingMenuItem({
    required String name,
    required String category,
    required int quantity,
    required double percentage,
    required Color color,
  }) {
    IconData icon = Icons.fastfood;
    Color iconColor = const Color(0xFFF2994A);
    Color bgColor = const Color(0xFFFFF3F0);
    
    if (category.contains('minum')) {
      icon = Icons.local_drink;
      iconColor = const Color(0xFF2F80ED);
      bgColor = const Color(0xFFEBF3FF);
    } else if (category.contains('snack') || category.contains('cemilan') || category.contains('jajanan')) {
      icon = Icons.cookie;
      iconColor = const Color(0xFF27AE60);
      bgColor = const Color(0xFFEEF9F1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          
          // Name & Quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity Porsi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress & percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 60 * (percentage / 100),
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
