import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

import '../widgets/seller_navbar.dart';
import '../../seller/features/orders/screens/order_list_screen.dart';
import '../../seller/features/menu/screens/menu_list_screen.dart';
import '../../seller/features/scanner/screens/qr_scanner_screen.dart';
import '../../seller/features/profile/screens/profile.dart';
import '../../seller/features/finance/screens/finance_report_screen.dart';
import '../../seller/features/finance/screens/seller_order_history_screen.dart';
import '../../seller/features/finance/services/finance_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class SellerMainLayout extends StatefulWidget {
  const SellerMainLayout({super.key});

  @override
  State<SellerMainLayout> createState() => _SellerMainLayoutState();
}

class _SellerMainLayoutState extends State<SellerMainLayout> {
  int _selectedIndex = 0;
  String _userRole = 'pegawai';
  bool _isLoadingRole = true;

  List<Widget>? _screens;

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
      _screens = [
        const OrderListScreen(),
        const MenuListScreen(),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(),
          child: _userRole == 'pemilik' 
              ? const FinanceReportScreen() 
              : SellerOrderHistoryScreen(userRole: _userRole, isFromTab: true),
        ),
        const ProfileTokoScreen(), // Profil Screen
      ];
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
    if (_isLoadingRole || _screens == null) {
      return const Scaffold(
        body: Center(child: AppLoadingAnimation()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens!,
      ),
      bottomNavigationBar: SellerNavbar(
        currentIndex: _selectedIndex,
        userRole: _userRole,
        onTap: _onItemTapped,
        onQrTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          );
        },
        primaryColor: _userRole == 'pegawai'
            ? const Color(0xFF5E7AC4)
            : const Color(0xFF3949AB),
      ),
    );
  }
}
