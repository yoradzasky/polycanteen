import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';
import '../../orders/screens/queue_ticket_screen.dart';
import '../../orders/services/order_service.dart';
import 'qris_payment_screen.dart';

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
        _isLoadingDetails = false;
      });
    } catch (e) {
      print('DEBUG: Error loading order details: $e');
      setState(() => _isLoadingDetails = false);
    }
  }

  String _formatOrderType(String type) {
    switch (type.toLowerCase()) {
      case 'takeaway':
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuat pembayaran: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTotal = _formatCurrency(widget.totalHarga);

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
                  onChanged: (type) => setState(() => _selectedOrderType = type),
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
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                
                const SectionTitle(title: 'Metode Pembayaran'),
                PaymentMethodSelectorHorizontal(
                  selectedMethod: _selectedMethod,
                  onChanged: (method) {
                    setState(() => _selectedMethod = method);
                  },
                ),
                const SizedBox(height: 24),
                
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
                    onPressed: _isLoading ? null : _handlePayment,
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
                              const Icon(Icons.credit_card, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Bayar Sekarang - $formattedTotal',
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
  const OrderItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.qty,
    this.imagePath,
  });

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
