import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

import '../widgets/seller_navbar.dart';
import '../../seller/features/orders/screens/order_list_screen.dart';
import '../../seller/features/menu/screens/menu_list_screen.dart';

class SellerMainLayout extends StatefulWidget {
  const SellerMainLayout({super.key});

  @override
  State<SellerMainLayout> createState() => _SellerMainLayoutState();
}

class _SellerMainLayoutState extends State<SellerMainLayout> {
  int _selectedIndex = 0;
  String _userRole = 'pegawai';
  bool _isLoadingRole = true;

  final List<Widget> _screens = [
    const OrderListScreen(),
    const MenuListScreen(),
    const Center(child: Text("Halaman Belum Tersedia")), // Placeholder for Laporan/Riwayat
    const Center(child: Text("Halaman Profil Belum Tersedia")), // Placeholder for Profil
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = EncryptedSharedPreferences();
    final role = await prefs.getString('user_role');
    if (!mounted) return;
    setState(() {
      _userRole = role.isNotEmpty ? role : 'pegawai';
      _isLoadingRole = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SellerNavbar(
        currentIndex: _selectedIndex,
        userRole: _userRole,
        onTap: _onItemTapped,
        onQrTap: () => debugPrint("Buka Scan QR"),
        primaryColor: _userRole == 'pegawai'
            ? const Color(0xFF5E7AC4)
            : const Color(0xFF3949AB),
      ),
    );
  }
}
