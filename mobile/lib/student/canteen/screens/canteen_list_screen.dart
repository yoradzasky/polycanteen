import 'package:flutter/material.dart';
import '../services/canteen_list_services.dart';
import '../../menu/screens/canteen_menu_screen.dart';
import '../../menu/services/menu_service.dart';
import '../../menu/widgets/keranjang.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class CanteenListScreen extends StatefulWidget {
  const CanteenListScreen({super.key});

  @override
  State<CanteenListScreen> createState() => _CanteenListScreenState();
}

class _CanteenListScreenState extends State<CanteenListScreen> {
  List<dynamic> kantinList = [];
  bool isLoading = true;

  final CanteenListService _canteenService = CanteenListService();
  final MenuService _menuService = MenuService();

  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchKantinData();
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    try {
      final cartData = await _menuService.getCartItems();
      if (mounted) {
        setState(() {
          cartItems = cartData
              .map((item) {
                return {
                  'menu_id': item['menu_id'],
                  'nama_item': item['menu'] != null
                      ? item['menu']['nama_item']
                      : 'Menu',
                  'harga_dasar': item['menu'] != null
                      ? double.tryParse(item['menu']['harga'].toString()) ?? 0.0
                      : 0.0,
                  'jumlah': item['jumlah'],
                  'varian_selected': item['varian_selected'],
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat keranjang di Menu: $e');
    }
  }

  Future<void> fetchKantinData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _canteenService.getKantinList();

      setState(() {
        kantinList = data;
        isLoading = false;
      });
      fetchCartData();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Exception: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'https://via.placeholder.com/150';
    if (path.startsWith('http')) return path;
    return '${_canteenService.baseUrlForStorage}/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERBAIKAN WARNA BACKGROUND: Menggunakan FFF6ED sesuai permintaan
      backgroundColor: const Color(0xFFFFF6ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Menu',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: fetchKantinData,
            color: const Color(0xFFF2994A),
            child: isLoading
                ? const Center(child: AppLoadingAnimation())
                : kantinList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text("Belum ada data kantin")),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    children: [
                      const Text(
                        'Silakan pilih kantin yang\nanda inginkan!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B399B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...kantinList.map((kantin) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildKantinCard(kantin),
                        );
                      }),
                      SizedBox(height: cartItems.isNotEmpty ? 100 : 0),
                    ],
                  ),
          ),
          if (cartItems.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: KeranjangWidget(
                cartItems: cartItems,
                onCartCheckedOut: () {
                  fetchKantinData();
                  fetchCartData();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKantinCard(Map<String, dynamic> kantin) {
    double rating =
        double.tryParse(kantin['ulasan_avg_rating']?.toString() ?? '0') ?? 0.0;
    int reviewCount =
        int.tryParse(kantin['ulasan_count']?.toString() ?? '0') ?? 0;

    String ratingDisplay = rating > 0 ? rating.toStringAsFixed(1) : "0.0";

    String imageUrl = _getImageUrl(kantin['logo_path']);
    bool isBuka = kantin['status_toko']?.toString().toLowerCase() == 'buka';
    bool isTutup = !isBuka;

    Widget imageWidget = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              );
            },
          )
        : const Center(
            child: Icon(Icons.store, size: 50, color: Colors.grey),
          );

    return GestureDetector(
      onTap: () {
        // PERBAIKAN: Navigasi ke CanteenMenuScreen dengan membawa data kantin
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CanteenMenuScreen(kantinData: kantin),
          ),
        ).then((_) => fetchCartData());
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: isTutup
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                        child: imageWidget,
                      )
                    : imageWidget,
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF1B399B).withValues(alpha: 0.85),
                        const Color(0xFF1B399B).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 30,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kantin['nama_kantin'] ?? 'Kantin Tanpa Nama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          // PERBAIKAN WARNA BINTANG: Lebih oranye, konsisten dengan tema
                          color: Color(0xFFF2994A),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$ratingDisplay ($reviewCount ulasan)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge Status Buka / Tutup
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isBuka
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBuka
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBuka
                            ? 'Buka'
                            : 'Tutup',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
