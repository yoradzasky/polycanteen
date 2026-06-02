/// Model untuk item dalam keranjang belanja
/// AC 4: Aplikasi Flutter menggunakan state management (Provider/Riverpod) untuk mengelola data keranjang lokal
class CartItem {
  final int id;
  final int menuId;
  final int kantinId;
  final String menuName;
  final double harga;
  final String fotoMenu;
  int jumlah;
  final List<VarianOption>? varianSelected;
  final List<ToppingOption>? toppingSelected;

  CartItem({
    required this.id,
    required this.menuId,
    required this.kantinId,
    required this.menuName,
    required this.harga,
    required this.fotoMenu,
    required this.jumlah,
    this.varianSelected,
    this.toppingSelected,
  });

  /// Hitung harga per item termasuk varian dan topping
  double get itemPrice {
    double price = harga;
    
    if (varianSelected != null) {
      price += varianSelected!.fold(0, (sum, v) => sum + v.harga);
    }
    
    if (toppingSelected != null) {
      price += toppingSelected!.fold(0, (sum, t) => sum + t.harga);
    }
    
    return price;
  }

  /// Hitung subtotal: (harga + varian + topping) * jumlah
  double get subtotal => itemPrice * jumlah;

  /// Increment jumlah
  void incrementQuantity() {
    jumlah++;
  }

  /// Decrement jumlah
  void decrementQuantity() {
    if (jumlah > 1) {
      jumlah--;
    }
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      menuId: json['menu_id'] ?? 0,
      kantinId: json['kantin_id'] ?? 0,
      menuName: json['menu']['nama_menu'] ?? '',
      harga: (json['menu']['harga'] ?? 0).toDouble(),
      fotoMenu: json['menu']['foto_menu'] ?? '',
      jumlah: json['jumlah'] ?? 1,
      varianSelected: json['varian_selected'] != null
          ? List<VarianOption>.from(
              (json['varian_selected'] as List)
                  .map((x) => VarianOption.fromJson(x)))
          : null,
      toppingSelected: json['topping_selected'] != null
          ? List<ToppingOption>.from(
              (json['topping_selected'] as List)
                  .map((x) => ToppingOption.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_id': menuId,
        'kantin_id': kantinId,
        'jumlah': jumlah,
        'varian_selected': varianSelected?.map((v) => v.toJson()).toList(),
        'topping_selected': toppingSelected?.map((t) => t.toJson()).toList(),
      };
}

/// Model untuk opsi varian (e.g., ukuran, rasa)
class VarianOption {
  final int id;
  final String nama;
  final double harga;

  VarianOption({
    required this.id,
    required this.nama,
    required this.harga,
  });

  factory VarianOption.fromJson(Map<String, dynamic> json) {
    return VarianOption(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: (json['harga'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
      };
}

/// Model untuk opsi topping
class ToppingOption {
  final int id;
  final String nama;
  final double harga;

  ToppingOption({
    required this.id,
    required this.nama,
    required this.harga,
  });

  factory ToppingOption.fromJson(Map<String, dynamic> json) {
    return ToppingOption(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: (json['harga'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
      };
}
