import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../../order/screens/order_screen.dart';

class QueueTicketScreen extends StatefulWidget {
  final int pesananId;

  const QueueTicketScreen({super.key, required this.pesananId});

  @override
  State<QueueTicketScreen> createState() => _QueueTicketScreenState();
}

class _QueueTicketScreenState extends State<QueueTicketScreen> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final data = await _orderService.getOrderDetail(widget.pesananId);
      setState(() {
        _orderData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount ?? 0);
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF08D38))),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOrderDetails,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _orderData!;
    final items = order['detail_pesanan'] as List<dynamic>? ?? [];
    String antreanNomor = order['nomor_antrian'] ?? '-';
    if (antreanNomor != '-' && antreanNomor.isNotEmpty) {
      final parts = antreanNomor.split('-');
      if (parts.length == 2) {
        final prefix = parts[0].trim();
        final suffix = parts[1].trim();
        final number = int.tryParse(suffix);
        if (number != null) {
          antreanNomor = '$prefix- $number';
        }
      }
    }
    final String kantinNama = order['kantin']?['nama_kantin'] ?? 'Kantin PolyCanteen';
    final String waktu = _formatDateTime(order['created_at']);
    final double subtotal = items.fold(0.0, (sum, item) => sum + (double.tryParse(item['subtotal'].toString()) ?? 0));
    final double serviceFee = 1000.0; // Dummy service fee
    final double total = double.tryParse(order['total_harga'].toString()) ?? (subtotal + serviceFee);
    final String metodePembayaran = order['metode_pembayaran'] ?? 'QRIS';
    final String transaksiId = order['transaksi_id'] ?? 'TRX${order['id']}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4EB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Header Section
              _buildHeader(waktu, kantinNama),
              
              const SizedBox(height: 24),
              
              // Queue Card
              _buildQueueCard(antreanNomor),
              
              const SizedBox(height: 24),
              
              // Order Details Card
              _buildOrderDetailsCard(items, subtotal, serviceFee, total, metodePembayaran, transaksiId),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Beranda',
                        icon: Icons.home_outlined,
                        color: const Color(0xFFF08D39),
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/student-main', (route) => false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Pesanan Saya',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFFF08D39),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OrderScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String waktu, String kantinNama) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 15,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pembayaran Berhasil',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          waktu,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          kantinNama,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueCard(String nomor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3BE7A), Color(0xFFF08D38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Nomor Antrean Anda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nomor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'LUNAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(
    List<dynamic> items,
    double subtotal,
    double serviceFee,
    double total,
    String metode,
    String trxId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item['jumlah_pesanan']}x ${item['menu']?['nama_item'] ?? 'Menu'}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  ),
                ),
                Text(
                  _formatCurrency(double.tryParse(item['subtotal'].toString()) ?? 0),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biaya Layanan', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
              Text(_formatCurrency(serviceFee), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Bayar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              Text(
                _formatCurrency(total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Metode Pembayaran', metode.toUpperCase()),
          const SizedBox(height: 12),
          _buildInfoRow('ID Transaksi', trxId),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
