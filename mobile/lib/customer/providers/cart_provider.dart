import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_item.dart';

/// AC 4: Cart Provider - Mengelola state keranjang lokal menggunakan Provider
/// Bertanggung jawab untuk:
/// 1. Mengelola list item dalam keranjang
/// 2. Sinkronisasi dengan API backend
/// 3. Calculate total harga dan summary keranjang
class CartProvider extends ChangeNotifier {
  final String apiBaseUrl = 'http://192.168.1.100:8000/api'; // Ganti dengan URL backend Anda
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  // GETTER
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Total items dalam keranjang
  int get totalItems => _items.fold(0, (sum, item) => sum + item.jumlah);
  
  /// Total harga semua item
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  /// FETCH CART dari server
  Future<void> fetchCart(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _items = List<CartItem>.from(
          (data['data'] as List).map((item) => CartItem.fromJson(item)),
        );
      } else {
        _error = 'Failed to fetch cart';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ADD ITEM TO CART
  Future<void> addToCart({
    required String token,
    required int menuId,
    required int kantinId,
    required int jumlah,
    List<VarianOption>? varian,
    List<ToppingOption>? topping,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'menu_id': menuId,
        'kantin_id': kantinId,
        'jumlah': jumlah,
        'varian_selected': varian?.map((v) => v.toJson()).toList(),
        'topping_selected': topping?.map((t) => t.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh cart list setelah berhasil menambah
        await fetchCart(token);
      } else {
        _error = 'Failed to add item to cart';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UPDATE CART ITEM (quantity atau varian)
  Future<void> updateCartItem({
    required String token,
    required int cartItemId,
    required int jumlah,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/cart/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'jumlah': jumlah}),
      );

      if (response.statusCode == 200) {
        await fetchCart(token);
      } else {
        _error = 'Failed to update cart item';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// REMOVE ITEM FROM CART
  Future<void> removeCartItem({
    required String token,
    required int cartItemId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/cart/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _items.removeWhere((item) => item.id == cartItemId);
        notifyListeners();
      } else {
        _error = 'Failed to remove item';
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// CLEAR ALL CART
  Future<void> clearCart(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/cart/clear/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _items.clear();
        notifyListeners();
      } else {
        _error = 'Failed to clear cart';
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// INCREMENT QUANTITY (local update)
  void incrementQuantity(int cartItemId) {
    final item = _items.firstWhere((i) => i.id == cartItemId, orElse: () => _items[0]);
    item.incrementQuantity();
    notifyListeners();
  }

  /// DECREMENT QUANTITY (local update)
  void decrementQuantity(int cartItemId) {
    final item = _items.firstWhere((i) => i.id == cartItemId, orElse: () => _items[0]);
    item.decrementQuantity();
    notifyListeners();
  }

  /// Get cart items by kantin (untuk checkout per kantin)
  List<CartItem> getCartByKantin(int kantinId) {
    return _items.where((item) => item.kantinId == kantinId).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
