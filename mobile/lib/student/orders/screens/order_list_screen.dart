import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  
  // Note: Since we don't have a listOrders API yet in the provided snippets, 
  // I will assume a standard implementation or use dummy data if needed.
  // For now, I'll focus on the UI refactoring and the requested logic.
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF4EB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2D50EE),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF2D50EE),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Dalam Proses'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(isHistory: false),
          _buildOrderList(isHistory: true),
        ],
      ),
    );
  }

  Widget _buildOrderList({required bool isHistory}) {
    // This would typically fetch from API. 
    // Showing how to use the refactored OrderCard.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Dummy count
      itemBuilder: (context, index) {
        return OrderCard(
          orderId: 3421 + index,
          items: index == 0 ? 'Nasi Goreng Special + Soto Ayam' : 'Gado-Gado',
          totalHarga: index == 0 ? 73000 : 15000,
          status: isHistory ? 'Selesai' : 'Siap Diambil',
          tipePesanan: index == 0 ? 'pengantaran' : 'dine_in',
          onTapDetail: () {
             // Navigate to detail
          },
          onTapLacak: () {
             // Navigate to tracking
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final int orderId;
  final String items;
  final double totalHarga;
  final String status;
  final String tipePesanan; // 'pengantaran', 'dine_in', 'take_away'
  final VoidCallback onTapDetail;
  final VoidCallback? onTapLacak;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.items,
    required this.totalHarga,
    required this.status,
    required this.tipePesanan,
    required this.onTapDetail,
    this.onTapLacak,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDelivery = tipePesanan == 'pengantaran';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pesanan #$orderId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 16),

          // Content: Items & Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Image Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFF2D50EE)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalHarga),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logic Button: Lacak Pesanan vs Detail Pesanan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDelivery ? onTapLacak : onTapDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D50EE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isDelivery ? 'Lacak Pesanan' : 'Detail Pesanan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'selesai':
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF16A34A);
        break;
      case 'siap diambil':
      case 'siap_diambil':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF2563EB);
        break;
      case 'dimasak':
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
