import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

/// AC 5: Checkout Screen
/// Fitur:
/// - Tab/pilihan pengiriman (Makan di Tempat, Bungkus, Pengantaran)
/// - Form input catatan/lokasi
/// - Ringkasan biaya (subtotal, biaya layanan, total)
class CheckoutScreen extends StatefulWidget {
  final int kantinId;

  const CheckoutScreen({
    super.key,
    required this.kantinId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // DELIVERY OPTIONS
  late String selectedDeliveryType = 'dine_in'; // dine_in, takeaway, delivery
  
  // FORM CONTROLLERS
  late TextEditingController catatanController;
  late TextEditingController alamatController;
  
  double? currentLatitude;
  double? currentLongitude;
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    catatanController = TextEditingController();
    alamatController = TextEditingController();
    
    // Load checkout preview saat screen pertama kali dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckoutPreview();
    });
  }

  @override
  void dispose() {
    catatanController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  /// Load checkout preview dari server
  Future<void> _loadCheckoutPreview() async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final token = ''; // Get from auth provider/storage
    
    await checkoutProvider.previewCheckout(
      token: token,
      kantinId: widget.kantinId,
      tipePesanan: selectedDeliveryType,
    );
  }

  /// Get current location untuk delivery
  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
        // Bisa tambahkan reverse geocoding untuk mendapatkan alamat dari koordinat
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  /// Process checkout
  Future<void> _processCheckout() async {
    // Validasi
    if (selectedDeliveryType == 'delivery' && alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman harus diisi')),
      );
      return;
    }

    final checkoutProvider = context.read<CheckoutProvider>();
    final token = ''; // Get from auth provider/storage
    
    final success = await checkoutProvider.processCheckout(
      token: token,
      kantinId: widget.kantinId,
      tipePesanan: selectedDeliveryType,
      catatanPesanan: catatanController.text,
      alamatPengiriman: alamatController.text,
      latitude: currentLatitude,
      longitude: currentLongitude,
    );

    if (success && mounted) {
      // Navigate ke order confirmation atau payment screen
      // Navigator.of(context).pushReplacementNamed('/order-confirmation', arguments: {
      //   'pesanId': checkoutProvider.currentOrder?.id,
      // });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout berhasil!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${checkoutProvider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== CART SUMMARY =====
            _buildCartSummary(),
            
            Divider(height: 24, thickness: 8, color: Colors.grey[200]),

            // ===== DELIVERY OPTIONS TAB =====
            _buildDeliveryOptions(),

            Divider(height: 24, thickness: 8, color: Colors.grey[200]),

            // ===== DELIVERY FORM (conditional) =====
            if (selectedDeliveryType == 'delivery')
              _buildDeliveryForm(),

            // ===== NOTES FORM =====
            _buildNotesForm(),

            Divider(height: 24, thickness: 8, color: Colors.grey[200]),

            // ===== COST SUMMARY =====
            _buildCostSummary(),

            // ===== CHECKOUT BUTTON =====
            _buildCheckoutButton(),
          ],
        ),
      ),
    );
  }

  /// Build cart items summary
  Widget _buildCartSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartItems = cartProvider.getCartByKantin(widget.kantinId);
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...cartItems.map((item) => _buildCartItemRow(item)),
            ],
          ),
        );
      },
    );
  }

  /// Build cart item row
  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.jumlah}x @ ${CheckoutProvider.formatCurrency(item.itemPrice)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            CheckoutProvider.formatCurrency(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build delivery options (AC 5)
  Widget _buildDeliveryOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilihan Pengiriman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // DINE_IN OPTION
              Expanded(
                child: _buildDeliveryOption(
                  value: 'dine_in',
                  label: 'Makan di Tempat',
                  icon: Icons.restaurant,
                ),
              ),
              const SizedBox(width: 12),
              // TAKEAWAY OPTION
              Expanded(
                child: _buildDeliveryOption(
                  value: 'takeaway',
                  label: 'Bungkus',
                  icon: Icons.shopping_bag,
                ),
              ),
              const SizedBox(width: 12),
              // DELIVERY OPTION
              Expanded(
                child: _buildDeliveryOption(
                  value: 'delivery',
                  label: 'Pengantaran',
                  icon: Icons.delivery_dining,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build single delivery option
  Widget _buildDeliveryOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedDeliveryType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeliveryType = value;
        });
        _loadCheckoutPreview();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build delivery form (for delivery type)
  Widget _buildDeliveryForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pengantaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // LOCATION BUTTON
          ElevatedButton.icon(
            onPressed: isLoadingLocation ? null : _getCurrentLocation,
            icon: isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_on),
            label: Text(
              currentLatitude != null
                  ? 'Lokasi: ${currentLatitude!.toStringAsFixed(4)}, ${currentLongitude!.toStringAsFixed(4)}'
                  : 'Ambil Lokasi Saat Ini',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ALAMAT TEXT FIELD
          TextField(
            controller: alamatController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Alamat Pengiriman',
              hintText: 'Masukkan alamat lengkap untuk pengantaran',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Build notes form (AC 5)
  Widget _buildNotesForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: catatanController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Catatan khusus (opsional)',
              hintText: 'Contoh: Tidak pakai cabe, tofu ganti telur, dll',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Build cost summary (AC 5)
  Widget _buildCostSummary() {
    return Consumer<CheckoutProvider>(
      builder: (context, checkoutProvider, _) {
        final preview = checkoutProvider.checkoutPreview;
        
        if (preview == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final subtotal = (preview['subtotal'] as num).toDouble();
        final biayaLayanan = (preview['biaya_layanan'] as num).toDouble();
        final total = (preview['total'] as num).toDouble();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // SUBTOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(CheckoutProvider.formatCurrency(subtotal)),
                  ],
                ),
                const SizedBox(height: 8),
                
                // SERVICE FEE
                if (biayaLayanan > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Biaya Layanan'),
                      Text(CheckoutProvider.formatCurrency(biayaLayanan)),
                    ],
                  ),
                
                if (biayaLayanan > 0)
                  const SizedBox(height: 8),
                
                // DIVIDER
                Divider(color: Colors.grey[300]),
                
                const SizedBox(height: 8),
                
                // TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      CheckoutProvider.formatCurrency(total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build checkout button
  Widget _buildCheckoutButton() {
    return Consumer<CheckoutProvider>(
      builder: (context, checkoutProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: checkoutProvider.isLoading ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: checkoutProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Lanjut ke Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
