import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VariantBottomSheet extends StatefulWidget {
  final Map<String, dynamic> menuData;
  // ✨ HANYA MENERIMA 2 PARAMETER SEKARANG
  final Function(int qty, Map? varianSelected) onAddToCart;

  const VariantBottomSheet({
    super.key,
    required this.menuData,
    required this.onAddToCart,
  });

  @override
  State<VariantBottomSheet> createState() => _VariantBottomSheetState();
}

class _VariantBottomSheetState extends State<VariantBottomSheet> {
  int quantity = 1;

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

  // Safe parser untuk Varian dari Backend
  List<dynamic> get varianList {
    if (widget.menuData['varian'] != null &&
        widget.menuData['varian'] is List) {
      return widget.menuData['varian'];
    }
    return [];
  }

  // Fungsi untuk menginisialisasi nilai default berdasarkan data dinamis
  void _initializeDynamicVariants() {
    for (var group in varianList) {
      if (group is Map) {
        String namaGroup = group['nama']?.toString() ?? 'Varian';
        String tipe = group['tipe']?.toString().toLowerCase() ?? 'opsional';
        List<dynamic> pilihan =
            group['pilihan'] is List ? group['pilihan'] : [];

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Render Varian Dinamis
          if (varianList.isNotEmpty)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: varianList.map((group) {
                    if (group is! Map) return const SizedBox();

                    String namaGroup = group['nama']?.toString() ?? 'Varian';
                    String tipe =
                        group['tipe']?.toString().toLowerCase() ?? 'opsional';
                    List<dynamic> pilihanList =
                        group['pilihan'] is List ? group['pilihan'] : [];

                    if (pilihanList.isEmpty) return const SizedBox();
                    bool isWajib = tipe == 'wajib';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Grup (Judul & Badge)
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

                        // List Pilihan dalam Grup
                        ...pilihanList.map((item) {
                          String itemName = _getItemName(item);
                          int itemPrice = _getItemPrice(item);

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

                          // RADIO BUTTON UNTUK YANG WAJIB
                          if (isWajib) {
                            bool isSelected = selectedWajib[namaGroup] == item;
                            return InkWell(
                              onTap: () => setState(
                                () => selectedWajib[namaGroup] = item,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
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
                                    Theme(
                                      data: ThemeData(
                                        unselectedWidgetColor:
                                            Colors.grey.shade400,
                                      ),
                                      child: Radio<dynamic>(
                                        value: item,
                                        groupValue: selectedWajib[namaGroup],
                                        activeColor: const Color(0xFFF2994A),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (value) => setState(
                                          () => selectedWajib[namaGroup] = value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // CHECKBOX UNTUK YANG OPSIONAL
                          else {
                            bool isChecked =
                                selectedOpsional[namaGroup]?.contains(item) ??
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
                                      selectedOpsional[namaGroup]?.add(item);
                                    } else {
                                      selectedOpsional[namaGroup]?.remove(item);
                                    }
                                  });
                                },
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 20),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

          // Footer (Qty & Submit)
          Row(
            children: [
              // Qty Counter
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Submit Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2994A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    // Gabungkan semua payload varian
                    Map<String, dynamic> varianPayload = {};
                    selectedWajib.forEach(
                        (key, value) => varianPayload[key] = value);
                    selectedOpsional.forEach((key, list) {
                      if (list.isNotEmpty) {
                        varianPayload[key] = list;
                      }
                    });

                    widget.onAddToCart(
                      quantity,
                      varianPayload.isNotEmpty ? varianPayload : null,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Tambah ke\nKeranjang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}