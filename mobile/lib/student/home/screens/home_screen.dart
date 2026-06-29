import 'package:flutter/material.dart';
import 'package:mobile/student/home/widgets/custom_snackbar.dart';
import '../services/home_service.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/services/auth_service.dart';
import '../../../core/auth/screens/login_screen.dart';
import '../widgets/filter_menu.dart';
import '../../menu/screens/menu_detail.dart';
import '../../order/screens/order_detail_screen.dart';
import '../../menu/services/menu_service.dart';
import '../../payment/screens/payment_screen.dart';
import '../../menu/widgets/keranjang.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  String errorMessage = '';

  String namaMahasiswa = "Mahasiswa";
  String fotoProfil = "https://via.placeholder.com/150";
  Map<String, dynamic>? activeOrder;
  List<dynamic> quickReorder = [];
  List<dynamic> expressMenus = [];

  List<dynamic> allMenus = [];
  List<dynamic> displayedMenus = [];
  List<String> availableCategories = [];

  // State Pencarian dan Filter Aktif
  String searchKeyword = "";
  String? activeCategory;
  String? activePriceSort;
  String? activeTimeSort;

  final HomeService _homeService = HomeService();
  final MenuService _menuService = MenuService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchHomeData();
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
                  'foto_menu': item['menu'] != null ? item['menu']['foto_menu'] : null,
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat keranjang di Beranda: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHomeData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _homeService.getBerandaData();

      setState(() {
        namaMahasiswa = data['user']['nama_mahasiswa'] ?? "Mahasiswa";
        fotoProfil =
            data['user']['foto_profil_path'] ??
            "https://via.placeholder.com/150";
        activeOrder = data['pesanan_aktif'];
        quickReorder = data['pesan_ulang'] ?? [];
        
        bool isMenuAvailable(dynamic menu) {
          final dynamic rawStok = menu['status_stok'];
          final bool isHabis = rawStok == false || rawStok == 0 || rawStok == '0';
          final bool isBuka = menu['kantin']?['status_toko']?.toString().toLowerCase() == 'buka';
          return !isHabis && isBuka;
        }

        expressMenus = (data['menu_ekspres'] as List? ?? []).where(isMenuAvailable).toList();
        allMenus = (data['semua_menu'] as List? ?? []).where(isMenuAvailable).toList();

        availableCategories = allMenus
            .map((m) => m['kategori'].toString())
            .toSet()
            .toList();

        _applySearchAndFilter();
        isLoading = false;
      });
      fetchCartData();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('Unauthenticated') || errorMsg.toLowerCase().contains('dinonaktifkan')) {
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          CustomSnackBar.show(
            context,
            message: 'Sesi berakhir atau akun dinonaktifkan. Silakan login kembali.',
            isError: true,
          );
        }
        return;
      }

      setState(() {
        errorMessage = errorMsg;
        isLoading = false;
      });
    }
  }

  Future<void> _handleQuickReorder(Map<String, dynamic> pastOrder) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: AppLoadingAnimation()),
    );

    try {
      final menuService = MenuService();

      // 1. Clear current cart
      await menuService.clearCart();

      // 2. Add each item from the past order to the cart
      final details = pastOrder['details'] as List<dynamic>;
      for (var detail in details) {
        final menuId = detail['menu_id'] as int;
        final qty =
            int.tryParse(detail['jumlah_pesanan']?.toString() ?? '1') ?? 1;
        final varianSelected = detail['varian_snapshot'];

        await menuService.addToCart(
          menuId: menuId,
          jumlah: qty,
          varianSelected: varianSelected,
        );
      }

      // 3. Perform checkout
      final orderData = await menuService.checkout();

      // Dismiss loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // 4. Navigate to PaymentScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              pesananId: orderData['id'],
              totalHarga: double.parse(orderData['total_harga'].toString()),
            ),
          ),
        ).then((_) => fetchHomeData());
      }
    } catch (e) {
      // Dismiss loading dialog if error
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal melakukan pesan ulang: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applySearchAndFilter() {
    List<dynamic> filtered = List.from(allMenus);

    // 1. Filter dari Search Bar
    if (searchKeyword.isNotEmpty) {
      filtered = filtered.where((menu) {
        final namaItem = menu['nama_item'].toString().toLowerCase();
        return namaItem.contains(searchKeyword.toLowerCase());
      }).toList();
    }

    // 2. Filter dari Kategori
    if (activeCategory != null) {
      filtered = filtered
          .where((menu) => menu['kategori'] == activeCategory)
          .toList();
    }

    // 3. Urutkan Gabungan (Harga dulu, baru Waktu jika harganya sama / waktu diminta)
    if (activePriceSort != null || activeTimeSort != null) {
      filtered.sort((a, b) {
        int result = 0;

        if (activePriceSort != null) {
          double priceA = double.tryParse(a['harga'].toString()) ?? 0;
          double priceB = double.tryParse(b['harga'].toString()) ?? 0;
          result = activePriceSort == 'asc'
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        }

        if (result == 0 && activeTimeSort != null) {
          int timeA = a['estimasi_waktu'] ?? 999;
          int timeB = b['estimasi_waktu'] ?? 999;
          result = activeTimeSort == 'asc'
              ? timeA.compareTo(timeB)
              : timeB.compareTo(timeA);
        }

        return result;
      });
    }

    setState(() {
      displayedMenus = filtered;
    });
  }

  void _applyFilter(String? category, String? priceSort, String? timeSort) {
    activeCategory = category;
    activePriceSort = priceSort;
    activeTimeSort = timeSort;
    _applySearchAndFilter();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterMenu(
          categories: availableCategories,
          initialCategory: activeCategory,
          initialPriceSort: activePriceSort,
          initialTimeSort: activeTimeSort,
          onApply: _applyFilter,
        );
      },
    );
  }

  String _buildPhotoUrl(String? fotoMenu) {
    if (fotoMenu == null || fotoMenu.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    if (fotoMenu.startsWith('http')) return fotoMenu;
    final base = _homeService.baseUrlForStorage;
    return '$base/storage/$fotoMenu';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF6ED),
        body: const Center(child: AppLoadingAnimation()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF6ED),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: fetchHomeData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2994A),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    bool hasActiveFilter =
        activeCategory != null ||
        activePriceSort != null ||
        activeTimeSort != null;

    bool isSearching = searchKeyword.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFFF2994A),
              onRefresh: fetchHomeData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // --- HEADER & ACTIVE ORDER ---
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                  _buildPhotoUrl(fotoProfil),
                                ),
                                onBackgroundImageError: (_, __) {},
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          " Halo, ",
                                          style: TextStyle(
                                            color: Color(0xFF828282),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _getGreetingTime(),
                                          style: const TextStyle(
                                            color: Color(0xFFF2994A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      namaMahasiswa,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (activeOrder != null) _buildActiveOrderCard(),
                      ],
                    ),
                  ),

                  // --- SEARCH BAR ---
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: const Color(0xFFFFF6ED),
                    elevation: 0,
                    scrolledUnderElevation: 2,
                    shadowColor: Colors.black.withOpacity(0.2),
                    toolbarHeight: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              searchKeyword = value;
                              _applySearchAndFilter();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Cari makanan atau minuman...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade400,
                            ),
                            suffixIcon: isSearching
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        searchKeyword = "";
                                        _applySearchAndFilter();
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- KONTEN LAINNYA ---
                  SliverList(
                    delegate: SliverChildListDelegate([
                      if (!isSearching) ...[
                        // --- PESAN ULANG CEPAT ---
                        if (quickReorder.isNotEmpty) ...[
                          _buildSectionHeader(
                            "Pesan Ulang Cepat",
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2994A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 14,
                                    color: Color(0xFFF2994A),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Riwayat",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF2994A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildQuickReorderList(),
                        ],

                        // --- MENU EKSPRES ---
                        if (expressMenus.isNotEmpty) ...[
                          _buildSectionHeader(
                            "Menu Ekspres",
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF2C94C,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                    color: Color(0xFFE2B93B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Siap < 5 mnt",
                                    style: TextStyle(
                                      color: Color(0xFFE2B93B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildExpressMenuList(),
                        ],
                      ],

                      // --- SEMUA MENU & TOMBOL FILTER ---
                      _buildSectionHeader(
                        isSearching ? "Hasil Pencarian" : "Semua Menu",
                        trailing: GestureDetector(
                          onTap: _showFilterBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: hasActiveFilter
                                  ? const Color(0xFFF2994A).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasActiveFilter
                                    ? const Color(0xFFF2994A)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: hasActiveFilter
                                      ? const Color(0xFFF2994A)
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Filter",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: hasActiveFilter
                                        ? const Color(0xFFD4823A)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildAllMenuList(),
                      SizedBox(height: cartItems.isNotEmpty ? 100 : 30),
                    ]),
                  ),
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
                    fetchHomeData();
                    fetchCartData();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildActiveOrderCard() {
    final status = activeOrder!['status_pesanan'];
    final tipe = activeOrder!['tipe_pesanan'];
    final details = activeOrder!['details'] as List;

    String menuNames = details.map((e) => e['menu']['nama_item']).join(' + ');
    double totalHarga = double.parse(activeOrder!['total_harga'].toString());

    bool isDimasak =
        (status == 'dimasak' ||
        status == 'siap_diambil' ||
        status == 'menunggu_dikirim' ||
        status == 'dalam_perjalanan' ||
        status == 'selesai');
    bool isSelesai =
        (status == 'siap_diambil' ||
        status == 'menunggu_dikirim' ||
        status == 'dalam_perjalanan' ||
        status == 'selesai');

    String label3 = (tipe == 'take_away') ? "Sedang Diantar" : "Siap Diambil";

    String alertText = "";
    if (tipe == 'take_away') {
      if (status == 'dalam_perjalanan') {
        alertText = "Pesanan Anda Sedang Diantar";
      } else if (status == 'selesai') {
        alertText = "Pesanan Anda telah sampai!";
      }
    } else {
      if (status == 'selesai') {
        alertText = "Pesanan Anda sudah siap diambil!";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF2994A).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF9C076), Color(0xFFF2994A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.5)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nomor Antrean",
                      style: TextStyle(
                        color: Color(0xFF7A5128),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      activeOrder!['nomor_antrian'] ?? '-',
                      style: const TextStyle(
                        color: Color(0xFF8B5A2B),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _statusStep("Diterima", true)),
                    _statusLine(isDimasak),
                    Expanded(child: _statusStep("Dimasak", isDimasak)),
                    _statusLine(isSelesai),
                    Expanded(child: _statusStep(label3, isSelesai)),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuNames,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF2A2A2A),
                            ),
                            // ✨ DITAMBAHKAN: Cegah string gabungan menu jadi berantakan kalau panjang
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${details.length} item pesanan",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Rp ${_currencyFormat.format(totalHarga)}",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (alertText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4EADC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF27AE60),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alertText,
                            style: const TextStyle(
                              color: Color(0xFF1E8449),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2994A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (activeOrder != null && activeOrder!['id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                              pesananId: activeOrder!['id'],
                            ),
                          ),
                        ).then((_) => fetchHomeData());
                      }
                    },
                    child: const Text(
                      "Lihat Pesanan",
                      style: TextStyle(
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
    );
  }

  Widget _statusStep(String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: active ? const Color(0xFF27AE60) : Colors.grey.shade300,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: active ? const Color(0xFF27AE60) : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _statusLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? const Color(0xFF27AE60) : Colors.grey.shade300,
        margin: const EdgeInsets.only(top: 11),
      ),
    );
  }

  String _getGreetingTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF2C3138),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildQuickReorderList() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: quickReorder.length,
        itemBuilder: (context, index) {
          final item = quickReorder[index];
          final details = item['details'] as List;

          String menuNames = details
              .map((e) => e['menu']['nama_item'])
              .join(' + ');
          String fotoMenu = _buildPhotoUrl(
            details.isNotEmpty ? details[0]['menu']['foto_menu'] : null,
          );
          String namaKantin = item['kantin']['nama_kantin'] ?? 'Kantin';
          double harga = double.parse(item['total_harga'].toString());

          return Container(
            width: 250,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        fotoMenu,
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 65,
                          height: 65,
                          color: Colors.grey[200],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuNames,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2C3138),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            namaKantin,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${_currencyFormat.format(harga)}",
                            style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 35,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2994A),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handleQuickReorder(item),
                    icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
                    label: const Text(
                      "Pesan 1 Klik",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpressMenuList() {
    if (expressMenus.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 215,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: expressMenus.length,
        itemBuilder: (context, index) {
          final menu = expressMenus[index];

          // ✨ 1. CEK STATUS STOK
          final dynamic rawStok = menu['status_stok'];
          final bool isHabis =
              rawStok == false || rawStok == 0 || rawStok == '0';

          String foto = _buildPhotoUrl(menu['foto_menu']);
          double harga = double.parse(menu['harga'].toString());
          int waktu = menu['estimasi_waktu'] ?? 0;
          String namaKantin = menu['kantin']?['nama_kantin'] ?? 'Kantin';

          return GestureDetector(
            // ✨ 2. KUNCI KLIK JIKA HABIS
            onTap: isHabis
                ? () {
                    CustomSnackBar.show(
                      context,
                      message: 'Menu ini sedang habis.',
                      isError: true,
                    );
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MenuDetailScreen(menuData: menu),
                      ),
                    ).then((_) => fetchCartData());
                  },
            child: Opacity(
              // ✨ Samakan opacity dengan daftar Semua Menu agar konsisten
              opacity: isHabis ? 0.85 : 1.0,
              child: Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      // ✨ 3. BUNGKUS GAMBAR DENGAN STACK UNTUK FILTER & OVERLAY
                      child: Stack(
                        children: [
                          ColorFiltered(
                            colorFilter: isHabis
                                ? const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  )
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  ),
                            child: Image.network(
                              foto,
                              height: 100,
                              width: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: double.infinity,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          if (isHabis)
                            Container(
                              height: 100,
                              width: 130,
                              color: Colors.black.withOpacity(0.5),
                              alignment: Alignment.center,
                              child: const Text(
                                'HABIS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu['nama_item'] ?? 'Menu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              // ✨ Warna teks jadi abu-abu jika habis
                              color: isHabis
                                  ? Colors.grey
                                  : const Color(0xFF2C3138),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            namaKantin,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "$waktu menit",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${_currencyFormat.format(harga)}",
                            style: TextStyle(
                              // ✨ Warna harga jadi abu-abu jika habis
                              color: isHabis
                                  ? Colors.grey
                                  : const Color(0xFF27AE60),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllMenuList() {
    if (displayedMenus.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              const Text(
                "Tidak ada menu yang sesuai.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    searchKeyword = "";
                    activeCategory = null;
                    activePriceSort = null;
                    activeTimeSort = null;
                    _applySearchAndFilter();
                  });
                },
                child: const Text(
                  "Hapus Filter & Pencarian",
                  style: TextStyle(color: Color(0xFFF2994A)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: displayedMenus.length,
      itemBuilder: (context, index) {
        final menu = displayedMenus[index];
        final int waktu = menu['estimasi_waktu'] ?? 0;

        // Cek status stok - handle boolean dan int/string
        final dynamic rawStok = menu['status_stok'];
        final bool isAvailable =
            rawStok == true || rawStok == 1 || rawStok == '1';

        final bool isGreen = waktu < 10;
        final Color badgeBg = isGreen
            ? const Color(0xFFE8F6EF)
            : const Color(0xFFFFF3CD);
        final Color badgeText = isGreen
            ? const Color(0xFF27AE60)
            : const Color(0xFFD4823A);

        String foto = _buildPhotoUrl(menu['foto_menu']);
        String namaKantin = menu['kantin']?['nama_kantin'] ?? 'Kantin';
        double harga = double.tryParse(menu['harga'].toString()) ?? 0;

        return GestureDetector(
          onTap: isAvailable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuDetailScreen(menuData: menu),
                    ),
                  ).then((_) => fetchCartData());
                }
              : null,
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.85,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Foto menu dengan overlay HABIS jika stok kosong
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColorFiltered(
                            colorFilter: isAvailable
                                ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  )
                                : const ColorFilter.matrix(<double>[
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                            child: Image.network(
                              foto,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          if (!isAvailable)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                              ),
                              child: const Center(
                                child: Text(
                                  'HABIS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu['nama_item'] ?? 'Menu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isAvailable
                                ? const Color(0xFF2C3138)
                                : Colors.grey,
                          ),
                          // ✨ DITAMBAHKAN: Hindari teks overflow
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          namaKantin,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          // ✨ DITAMBAHKAN: Hindari teks overflow
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "Rp ${_currencyFormat.format(harga)}",
                              style: TextStyle(
                                color: isAvailable
                                    ? const Color(0xFF27AE60)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? badgeBg
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAvailable ? "$waktu menit" : "Stok Habis",
                                style: TextStyle(
                                  color: isAvailable ? badgeText : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
