import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/variant_bottom_sheet.dart';
import '../widgets/keranjang.dart';
import '../services/menu_service.dart';
import 'menu_detail.dart';
import '../../home/widgets/custom_snackbar.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class CanteenMenuScreen extends StatefulWidget {
  final Map<String, dynamic> kantinData;

  const CanteenMenuScreen({super.key, required this.kantinData});

  @override
  State<CanteenMenuScreen> createState() => _CanteenMenuScreenState();
}

class _CanteenMenuScreenState extends State<CanteenMenuScreen> {
  bool isLoading = true;
  List<dynamic> allMenus = [];
  List<dynamic> filteredMenus = [];

  List<String> categories = ['Semua', 'Siap < 5 Menit'];
  String selectedCategory = 'Semua';

  String searchKeyword = "";
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> cartItems = [];

  final MenuService _menuService = MenuService();

  @override
  void initState() {
    super.initState();
    fetchMenuData();
    fetchCartData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchMenuData() async {
    setState(() => isLoading = true);

    try {
      int kantinId =
          int.tryParse(widget.kantinData['id']?.toString() ?? '0') ?? 0;
      final responseData = await _menuService.getMenuByKantin(kantinId);

      Set<String> uniqueCategories = {};
      for (var menu in responseData) {
        if (menu['kategori'] != null) uniqueCategories.add(menu['kategori']);
      }

      setState(() {
        allMenus = responseData;
        categories = ['Semua', 'Siap < 5 Menit', ...uniqueCategories.toList()];
        _applySearchAndFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  // ✨ FUNGSI YANG SUDAH DIBERSIHKAN DARI TOPPING
  Future<void> fetchCartData() async {
    try {
      final cartData = await _menuService.getCartItems();

      // Ambil ID Kantin yang sedang dibuka saat ini
      int currentKantinId =
          int.tryParse(widget.kantinData['id']?.toString() ?? '0') ?? 0;

      if (mounted) {
        setState(() {
          // 1. Saring (filter) data
          var filteredByKantin = cartData.where((item) {
            if (item['menu'] != null && item['menu']['kantin_id'] != null) {
              return item['menu']['kantin_id'].toString() ==
                  currentKantinId.toString();
            }
            return false;
          }).toList();

          // 2. Map data
          cartItems = filteredByKantin
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
                  // topping_selected dihapus
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat keranjang: $e');
    }
  }

  void _applySearchAndFilter() {
    List<dynamic> filtered = List.from(allMenus);

    if (searchKeyword.isNotEmpty) {
      filtered = filtered.where((menu) {
        final namaItem = menu['nama_item'].toString().toLowerCase();
        return namaItem.contains(searchKeyword.toLowerCase());
      }).toList();
    }

    if (selectedCategory != 'Semua') {
      if (selectedCategory == 'Siap < 5 Menit') {
        filtered = filtered.where((menu) {
          int estimasi =
              int.tryParse(menu['estimasi_waktu']?.toString() ?? '99') ?? 99;
          return estimasi < 5;
        }).toList();
      } else {
        filtered = filtered
            .where((menu) => menu['kategori'] == selectedCategory)
            .toList();
      }
    }

    setState(() {
      filteredMenus = filtered;
    });
  }

  void _setCategory(String category) {
    setState(() {
      selectedCategory = category;
      _applySearchAndFilter();
    });
  }

  String formatReviewCount(int count) {
    if (count >= 1000) {
      double value = count / 1000;
      return '${value == value.toInt() ? value.toInt() : value.toStringAsFixed(1)}rb+';
    }
    return count.toString();
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'https://via.placeholder.com/150';
    if (path.startsWith('http')) return path;
    return '${_menuService.baseUrlForStorage}/storage/$path';
  }

  // ✨ SUDAH DIBERSIHKAN DARI PARAMETER TOPPING
  Future<void> _prosesTambahKeranjang(Map menu, int qty, Map? varian) async {
    try {
      // 1. Tembak API Laravel untuk tambah keranjang
      await _menuService.addToCart(
        menuId: menu['id'],
        jumlah: qty,
        varianSelected: varian,
      );

      // 2. GANTI logika manual tadi dengan menarik ulang data keranjang
      // yang sudah dikalkulasi dengan benar oleh backend Laravel
      await fetchCartData();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.startsWith('different_kantin|')) {
          final kantinName = errorMsg.split('|')[1];
          _showClearCartConfirmDialog(kantinName, menu, qty, varian);
        } else {
          CustomSnackBar.show(
            context,
            message: errorMsg,
            isError: true,
          );
        }
      }
    }
  }

  void _showClearCartConfirmDialog(String kantinName, Map menu, int qty, Map? varian) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ganti Kantin?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Keranjang Anda berisi menu dari "$kantinName". '
            'Apakah Anda ingin mengosongkan keranjang untuk memesan menu dari kantin ini?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                try {
                  await _menuService.clearCart(); // Kosongkan keranjang
                  await _prosesTambahKeranjang(menu, qty, varian); // Panggil tambah keranjang lagi
                } catch (err) {
                  if (mounted) {
                    CustomSnackBar.show(
                      context,
                      message: err.toString().replaceAll('Exception: ', ''),
                      isError: true,
                    );
                  }
                }
              },
              child: const Text('Ya, Kosongkan', style: TextStyle(color: const Color(0xFFF2994A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Helper: cek apakah kantin sedang buka
  bool get _isKantinBuka {
    return widget.kantinData['status_toko']?.toString().toLowerCase() == 'buka';
  }

  // ✨ SUDAH DIBERSIHKAN DARI LOGIKA TOPPING
  void _handleAddToCartClick(Map<String, dynamic> menu) {
    // Blokir jika kantin tutup
    if (!_isKantinBuka) {
      CustomSnackBar.show(
        context,
        message: 'Kantin sedang tutup. Tidak bisa menambah ke keranjang.',
        isError: true,
      );
      return;
    }

    bool hasVarian =
        menu['varian'] != null && (menu['varian'] as List).isNotEmpty;

    if (hasVarian) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VariantBottomSheet(
          menuData: menu,
          // onAddToCart sekarang HANYA mengembalikan qty dan varian
          onAddToCart: (int qty, Map? varian) {
            _prosesTambahKeranjang(menu, qty, varian);
          },
        ),
      );
    } else {
      _prosesTambahKeranjang(menu, 1, null);
    }
  }

  int _getQtyInCart(int menuId) {
    int count = 0;
    for (var item in cartItems) {
      if (item['menu_id'] == menuId) count += (item['jumlah'] as int);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    double ratingKantin =
        double.tryParse(
          widget.kantinData['ulasan_avg_rating']?.toString() ?? '0',
        ) ??
        0.0;
    int reviewCount =
        int.tryParse(widget.kantinData['ulasan_count']?.toString() ?? '0') ?? 0;
    bool isSearching = searchKeyword.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // HEADER KANTIN DENGAN EFEK OVERLAPPING
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFFFFF6ED),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Lapis 1: Gambar Background Kantin
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 60,
                        child: widget.kantinData['logo_path'] != null
                            ? Image.network(
                                _getImageUrl(widget.kantinData['logo_path']),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: Colors.grey[300]),
                              )
                            : Container(color: Colors.grey[300]),
                      ),

                      // Lapis 2: Kotak Nama Kantin Overlapping
                      Positioned(
                        bottom: 0,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.kantinData['nama_kantin']
                                        ?.toString()
                                        .toUpperCase() ??
                                    'KANTIN',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // STATUS BUKA / TUTUP
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isKantinBuka
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isKantinBuka
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: _isKantinBuka
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFE53935),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isKantinBuka ? 'Buka' : 'Tutup',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: _isKantinBuka
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFE53935),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E9CD),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFF2C94C),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${ratingKantin.toStringAsFixed(1)} (${formatReviewCount(reviewCount)})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // SEARCH BAR STICKY
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
                                  FocusScope.of(
                                    context,
                                  ).unfocus(); // Menutup keyboard
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

              // TAB FILTER KATEGORI
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 0,
                    bottom: 15,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedCategory == categories[index];
                        return GestureDetector(
                          onTap: () => _setCategory(categories[index]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF2994A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (categories[index] == 'Siap < 5 Menit') ...[
                                  Icon(
                                    Icons.bolt,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  categories[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // DAFTAR MENU & EMPTY STATE
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: isLoading
                    ? const SliverToBoxAdapter(
                        child: const Center(child: AppLoadingAnimation()),
                      )
                    : filteredMenus.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 30),
                              Icon(
                                Icons.search_off,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Menu tidak ditemukan.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final menu = filteredMenus[index];
                          int qty = _getQtyInCart(menu['id']);
                          double ratingMenu =
                              double.tryParse(
                                menu['ulasan_avg_rating']?.toString() ?? '0',
                              ) ??
                              0.0;

                          double hargaDouble =
                              double.tryParse(
                                menu['harga']?.toString() ?? '0',
                              ) ??
                              0.0;
                          int harga = hargaDouble.toInt();

                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuDetailScreen(
                                    menuData: menu,
                                    isKantinBuka: _isKantinBuka,
                                  ),
                                ),
                              );

                              if (result == true ||
                                  (result != null && result is Map)) {
                                // Tarik ulang data keranjang terbaru dari database
                                fetchCartData();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: menu['foto_menu'] != null
                                          ? Image.network(
                                              _getImageUrl(menu['foto_menu']),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.fastfood,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.fastfood,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                menu['nama_item'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '🕒 ${menu['estimasi_waktu']} mnt',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          menu['deskripsi'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Color(0xFFF2C94C),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ratingMenu.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(harga),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (qty > 0) ...[
                                                  GestureDetector(
                                                    onTap: () async {
                                                      // 1. Cek ada berapa baris/macam varian untuk menu ini di keranjang
                                                      int
                                                      macamVarian = cartItems
                                                          .where(
                                                            (item) =>
                                                                item['menu_id'] ==
                                                                menu['id'],
                                                          )
                                                          .length;

                                                      // 2. Blokir jika variannya lebih dari 1 macam
                                                      if (macamVarian > 1) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Menu ini memiliki varian berbeda. Silakan atur jumlahnya di halaman Keranjang.',
                                                            ),
                                                            backgroundColor:
                                                                Colors.orange,
                                                            duration: Duration(
                                                              seconds: 2,
                                                            ),
                                                          ),
                                                        );
                                                        return; // Hentikan proses, jangan tembak API
                                                      }

                                                      // 3. Lanjutkan proses jika hanya 1 macam varian
                                                      try {
                                                        await _menuService
                                                            .decreaseCartQty(
                                                              menu['id'],
                                                            );

                                                        // Panggil fetchCartData() agar state selalu sinkron
                                                        // dengan perhitungan valid dari database (decrement vs delete baris)
                                                        fetchCartData();
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                e
                                                                    .toString()
                                                                    .replaceAll(
                                                                      'Exception: ',
                                                                      '',
                                                                    ),
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              Colors.grey[300]!,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '$qty',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                                GestureDetector(
                                                  onTap: _isKantinBuka
                                                      ? () =>
                                                          _handleAddToCartClick(
                                                            menu,
                                                          )
                                                      : () {
                                                          CustomSnackBar.show(
                                                            context,
                                                            message:
                                                                'Kantin sedang tutup. Tidak bisa menambah ke keranjang.',
                                                            isError: true,
                                                          );
                                                        },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _isKantinBuka
                                                            ? Colors.grey[300]!
                                                            : Colors.grey[200]!,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: _isKantinBuka
                                                          ? Colors.black
                                                          : Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: filteredMenus.length),
                      ),
              ),
            ],
          ),

          if (cartItems.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: KeranjangWidget(
                cartItems: cartItems,
                onCartCheckedOut: fetchCartData,
              ),
            ),
        ],
      ),
    );
  }
}
