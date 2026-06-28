import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/menu_service.dart';
import '../../../core/widgets/custom_snackbar.dart';

class MenuDetailScreen extends StatefulWidget {
  final Map<String, dynamic> menuData;

  const MenuDetailScreen({super.key, required this.menuData});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  final MenuService _menuService = MenuService();

  int qty = 1;
  bool isAddingToCart = false;

  // State untuk menyimpan pilihan yang dinamis
  // Map untuk WAJIB (Key: nama grup, Value: item pilihan)
  Map<String, dynamic> selectedWajib = {};
  // Map untuk OPSIONAL (Key: nama grup, Value: list item pilihan)
  Map<String, List<dynamic>> selectedOpsional = {};

  @override
  void initState() {
    super.initState();
    _initializeDynamicVariants();
  }

  // Fungsi untuk menginisialisasi nilai default berdasarkan data dinamis
  void _initializeDynamicVariants() {
    final varianList = _getVarianList();

    for (var group in varianList) {
      if (group is Map) {
        String namaGroup = group['nama']?.toString() ?? 'Varian';
        String tipe = group['tipe']?.toString().toLowerCase() ?? 'opsional';
        List<dynamic> pilihan = group['pilihan'] is List
            ? group['pilihan']
            : [];

        if (tipe == 'wajib' && pilihan.isNotEmpty) {
          // Set pilihan pertama sebagai default untuk yang wajib
          selectedWajib[namaGroup] = pilihan[0];
        } else if (tipe == 'opsional') {
          // Siapkan list kosong untuk yang opsional
          selectedOpsional[namaGroup] = [];
        }
      }
    }
  }

  // Safe parser untuk Varian dari Backend
  List<dynamic> _getVarianList() {
    if (widget.menuData['varian'] != null &&
        widget.menuData['varian'] is List) {
      return widget.menuData['varian'];
    }
    return [];
  }

  // Helper mendapatkan URL gambar
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/400x300';
    }
    if (path.startsWith('http')) return path;
    return '${_menuService.baseUrlForStorage}/storage/$path';
  }

  // Helper format jumlah ulasan
  String formatReviewCount(int count) {
    if (count >= 1000) {
      double value = count / 1000;
      return '${value == value.toInt() ? value.toInt() : value.toStringAsFixed(1)}rb+';
    }
    return count.toString();
  }

  // Helper mengekstrak nama dari item pilihan
  String _getItemName(dynamic item) {
    if (item is Map) return item['nama']?.toString() ?? 'Item';
    return item.toString();
  }

  // Helper mengekstrak harga dari item pilihan
  int _getItemPrice(dynamic item) {
    if (item is Map && item.containsKey('harga')) {
      double hargaDouble = double.tryParse(item['harga'].toString()) ?? 0.0;
      return hargaDouble.toInt();
    }
    return 0;
  }

  // Hitung total harga dinamis
  int _calculateTotalPrice() {
    double baseDouble =
        double.tryParse(widget.menuData['harga']?.toString() ?? '0') ?? 0.0;
    int total = baseDouble.toInt();

    // Tambah harga dari semua varian WAJIB yang dipilih
    selectedWajib.forEach((key, item) {
      total += _getItemPrice(item);
    });

    // Tambah harga dari semua varian OPSIONAL yang dicentang
    selectedOpsional.forEach((key, list) {
      for (var item in list) {
        total += _getItemPrice(item);
      }
    });

    return total * qty;
  }

  // Aksi tombol Tambah ke Keranjang
  Future<void> _handleAddToCart() async {
    setState(() => isAddingToCart = true);

    try {
      // Menggabungkan pilihan ke format yang diterima backend
      Map<String, dynamic> varianPayload = {};
      selectedWajib.forEach((key, value) => varianPayload[key] = value);
      selectedOpsional.forEach((key, list) {
        if (list.isNotEmpty) {
           varianPayload[key] = list; // Opsional dimasukkan sebagai array di dalam map varian
        }
      });

      await _menuService.addToCart(
        menuId: widget.menuData['id'],
        jumlah: qty,
        varianSelected: varianPayload.isNotEmpty ? varianPayload : null,
      );

      if (mounted) {
        Navigator.pop(context, {
          'qty': qty,
          'varian': varianPayload.isNotEmpty ? varianPayload : null,
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.startsWith('different_kantin|')) {
          final kantinName = errorMsg.split('|')[1];
          _showClearCartConfirmDialog(kantinName);
        } else {
          CustomSnackBar.show(
            context,
            message: errorMsg,
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) setState(() => isAddingToCart = false);
    }
  }

  void _showClearCartConfirmDialog(String kantinName) {
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
                setState(() => isAddingToCart = true);
                try {
                  await _menuService.clearCart(); // Kosongkan keranjang
                  await _handleAddToCart(); // Panggil tambah keranjang lagi
                } catch (err) {
                  if (mounted) {
                    CustomSnackBar.show(
                      context,
                      message: err.toString().replaceAll('Exception: ', ''),
                      isError: true,
                    );
                  }
                  if (mounted) setState(() => isAddingToCart = false);
                }
              },
              child: const Text('Ya, Kosongkan', style: TextStyle(color: const Color(0xFFF2994A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String namaMenu = widget.menuData['nama_item'] ?? 'Nama Menu';
    final String deskripsi =
        widget.menuData['deskripsi'] ?? 'Tidak ada deskripsi.';
    final String estimasi =
        widget.menuData['estimasi_waktu']?.toString() ?? '-';

    final double ratingMenu =
        double.tryParse(
          widget.menuData['ulasan_avg_rating']?.toString() ?? '0',
        ) ??
        0.0;
    final int ulasanCount =
        int.tryParse(widget.menuData['ulasan_count']?.toString() ?? '0') ?? 0;

    final double hargaHeaderDouble =
        double.tryParse(widget.menuData['harga']?.toString() ?? '0') ?? 0.0;
    final int hargaDasar = hargaHeaderDouble.toInt();

    final List<dynamic> varianList = _getVarianList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GAMBAR HEADER
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: widget.menuData['foto_menu'] != null
                      ? Image.network(
                          _getImageUrl(widget.menuData['foto_menu']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300]),
                        )
                      : Container(color: Colors.grey[300]),
                ),

                // AREA PUTIH OVERLAPPING (DETAIL MENU)
                Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF6ED),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NAMA MENU & HARGA DASAR
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              namaMenu,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(hargaDasar),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // RATING, ULASAN & WAKTU
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFF2C94C),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingMenu.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${formatReviewCount(ulasanCount)} ulasan)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.schedule,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$estimasi mnt',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // DESKRIPSI
                      Text(
                        deskripsi,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // RENDER VARIAN DINAMIS
                      ...varianList.map((group) {
                        if (group is! Map) return const SizedBox();

                        String namaGroup =
                            group['nama']?.toString() ?? 'Varian';
                        String tipe =
                            group['tipe']?.toString().toLowerCase() ??
                            'opsional';
                        List<dynamic> pilihanList = group['pilihan'] is List
                            ? group['pilihan']
                            : [];

                        if (pilihanList.isEmpty) return const SizedBox();
                        bool isWajib = tipe == 'wajib';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Grup (Judul & Badge Wajib/Opsional)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  namaGroup,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isWajib
                                        ? const Color(0xFFE5E9CD)
                                        : const Color(0xFFD6EADF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isWajib ? 'WAJIB' : 'OPSIONAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isWajib
                                          ? const Color(0xFF5C653C)
                                          : const Color(0xFF27AE60),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Looping Pilihan dalam Grup
                            ...pilihanList.map((item) {
                              String itemName = _getItemName(item);
                              int itemPrice = _getItemPrice(item);

                              // Widget Harga Ekstra
                              Widget priceWidget = Text(
                                itemPrice > 0
                                    ? '+Rp ${NumberFormat('#,###', 'id').format(itemPrice)}'
                                    : '+Rp 0',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF27AE60),
                                  fontWeight: FontWeight.w600,
                                ),
                              );

                              // ── RADIO (WAJIB): kontrol di kanan, harga di bawah nama ──
                              if (isWajib) {
                                bool isSelected =
                                    selectedWajib[namaGroup] == item;
                                return InkWell(
                                  onTap: () => setState(
                                    () => selectedWajib[namaGroup] = item,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        // Nama + Harga (kiri, harga di bawah nama)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                itemName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? Colors.black
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              priceWidget,
                                            ],
                                          ),
                                        ),
                                        // Radio di kanan
                                        Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor:
                                                Colors.grey.shade400,
                                          ),
                                          child: Radio<dynamic>(
                                            value: item,
                                            groupValue:
                                                selectedWajib[namaGroup],
                                            activeColor: const Color(
                                              0xFFF2994A,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            onChanged: (value) => setState(
                                              () => selectedWajib[namaGroup] =
                                                  value,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              // ── CHECKBOX (OPSIONAL): kontrol di kanan, harga di bawah nama ──
                              else {
                                bool isChecked =
                                    selectedOpsional[namaGroup]?.contains(
                                      item,
                                    ) ??
                                    false;
                                return Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: Colors.grey.shade400,
                                  ),
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: const VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                    activeColor: const Color(0xFFF2994A),
                                    value: isChecked,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedOpsional[namaGroup]?.add(
                                            item,
                                          );
                                        } else {
                                          selectedOpsional[namaGroup]?.remove(
                                            item,
                                          );
                                        }
                                      });
                                    },
                                    // Nama di atas, harga di bawah
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          itemName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isChecked
                                                ? Colors.black
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        priceWidget,
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TOMBOL BACK (KIRI ATAS FLOATING)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(10),
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
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // BOTTOM BAR: QTY & TAMBAH KE KERANJANG
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6ED),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // KONTROL QUANTITY (+ / -)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (qty > 1) setState(() => qty--);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: qty > 1 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => setState(() => qty++),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // TOMBOL TAMBAH KE KERANJANG
                    Expanded(
                      child: SizedBox(
                        height: 50, // Paksa tinggi tombol tetap 50
                        child: ElevatedButton(
                          onPressed: isAddingToCart ? null : _handleAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2994A),
                            disabledBackgroundColor: const Color(
                              0xFFF2994A,
                            ).withOpacity(0.7), // Warna saat loading
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isAddingToCart
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Pusatkan teks di tengah
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Tambah ke Keranjang',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp ',
                                        decimalDigits: 0,
                                      ).format(_calculateTotalPrice()),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}