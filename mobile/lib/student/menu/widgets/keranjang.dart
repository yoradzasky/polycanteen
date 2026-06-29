import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../payment/screens/payment_screen.dart';
import '../services/menu_service.dart';
import '../../home/widgets/custom_snackbar.dart';

class KeranjangWidget extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback? onCartCheckedOut;

  const KeranjangWidget({super.key, required this.cartItems, this.onCartCheckedOut});

  @override
  Widget build(BuildContext context) {
    // Menghitung total item dan total harga dinamis
    int totalItems = 0;
    double totalPrice = 0;

    for (var item in cartItems) {
      int qty = item['jumlah'] as int;
      totalItems += qty;
      
      double itemPrice = item['harga_dasar'] as double;
      
      // Hitung tambahan harga dari varian_selected (mendukung format Wajib & Opsional)
      if (item['varian_selected'] != null && item['varian_selected'] is Map) {
        Map varian = item['varian_selected'];
        varian.forEach((key, value) {
          // 1. Jika value berupa Map (Varian Wajib / Radio)
          if (value is Map && value.containsKey('harga')) {
            itemPrice += double.tryParse(value['harga'].toString()) ?? 0;
          } 
          // 2. Jika value berupa List (Varian Opsional / Checkbox)
          else if (value is List) {
            for (var v in value) {
              if (v is Map && v.containsKey('harga')) {
                itemPrice += double.tryParse(v['harga'].toString()) ?? 0;
              }
            }
          }
        });
      }
      
      totalPrice += (itemPrice * qty);
    }

    return GestureDetector(
      onTap: () async {
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                pesananId: null, // NOT checked out yet
                cartItems: cartItems,
                totalHarga: totalPrice,
              ),
            ),
          );
          if (onCartCheckedOut != null) {
            onCartCheckedOut!();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2994A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2994A).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalItems Item Pesanan',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id', 
                      symbol: 'Rp ', 
                      decimalDigits: 0
                    ).format(totalPrice),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            const Row(
              children: [
                Text(
                  'Keranjang',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white)
              ],
            )
          ],
        ),
      ),
    );
  }
}