import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

import '../services/menu_service.dart';
import 'add_menu_screen.dart';
import 'edit_menu_screen.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

// ──────────────────────────────────────────────
// Warna utama
// ──────────────────────────────────────────────
const Color _kPrimaryBlue = Color(0xFF3949AB);
const Color _kAccentOrange = Color(0xFFF57C00);
const Color _kAvailableGreen = Color(0xFF4CAF50);
const Color _kUnavailableGrey = Color(0xFFBDBDBD);

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final MenuService _menuService = MenuService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  List<Menu> _menus = [];
  bool _isLoading = true;
  String? _error;
  String _userRole = 'pegawai';
  Timer? _debounce;
  final int _currentNavIndex = 1; // Kelola Menu aktif

  Color get _primaryColor =>
      _userRole == 'pegawai' ? const Color(0xFF5E7AC4) : _kPrimaryBlue;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchMenus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final prefs = EncryptedSharedPreferences();
    final role = await prefs.getString('user_role');
    if (!mounted) return;
    setState(() {
      _userRole = role.isNotEmpty ? role : 'pegawai';
    });
  }

  Future<void> _fetchMenus({String? search}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final menus = await _menuService.getMenus(search: search);
      if (!mounted) return;
      setState(() {
        _menus = menus;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchMenus(search: value);
    });
  }

  Future<void> _handleToggle(int index) async {
    final menu = _menus[index];
    final previousStatus = menu.statusStok;

    // Optimistic update (SUDAH DIHAPUS TOPPING)
    setState(() {
      _menus[index] = Menu(
        id: menu.id,
        namaItem: menu.namaItem,
        harga: menu.harga,
        fotoMenu: menu.fotoMenu,
        statusStok: previousStatus == 'tersedia' ? 'habis' : 'tersedia',
        kategori: menu.kategori,
        deskripsi: menu.deskripsi,
        estimasiWaktu: menu.estimasiWaktu,
        pilihanLayanan: menu.pilihanLayanan,
        varian: menu.varian,
      );
    });

    try {
      await _menuService.toggleMenuStatus(menu.id);
    } catch (e) {
      // Revert on error (SUDAH DIHAPUS TOPPING)
      if (!mounted) return;
      setState(() {
        _menus[index] = Menu(
          id: menu.id,
          namaItem: menu.namaItem,
          harga: menu.harga,
          fotoMenu: menu.fotoMenu,
          statusStok: previousStatus,
          kategori: menu.kategori,
          deskripsi: menu.deskripsi,
          estimasiWaktu: menu.estimasiWaktu,
          pilihanLayanan: menu.pilihanLayanan,
          varian: menu.varian,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMenuScreen()),
    );
    if (result == true) {
      _fetchMenus(search: _searchController.text);
    }
  }

  void _navigateToEdit(Menu menu) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditMenuScreen(menu: menu)),
    );
    if (result == true) {
      _fetchMenus(search: _searchController.text);
    }
  }

  // ──────────────────────────────────────────
  // Foto URL helper
  // ──────────────────────────────────────────
  String? _buildPhotoUrl(String? fotoMenu) {
    if (fotoMenu == null || fotoMenu.isEmpty) return null;
    if (fotoMenu.startsWith('http')) return fotoMenu;
    // Assume storage/public base
    final base = _menuService.baseUrlForStorage;
    return '$base/storage/$fotoMenu';
  }

  // ──────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        centerTitle: true,
        title: const Text(
          'Daftar Menu Anda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          Container(
            color: _primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari nama menu...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ─── Body ───
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _userRole == 'pemilik'
          ? FloatingActionButton(
              onPressed: _navigateToAdd,
              backgroundColor: _kAccentOrange,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingAnimation());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchMenus(),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada menu.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan menu baru!',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () => _fetchMenus(search: _searchController.text),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _menus.length,
        itemBuilder: (context, index) => _buildMenuCard(index),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Menu Card
  // ──────────────────────────────────────────
  Widget _buildMenuCard(int index) {
    final menu = _menus[index];
    final isAvailable = menu.statusStok == 'tersedia';
    final photoUrl = _buildPhotoUrl(menu.fotoMenu);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ─── Foto ───
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            const SizedBox(width: 14),

            // ─── Info ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          menu.namaItem,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF212121),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_userRole == 'pemilik') ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _navigateToEdit(menu),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_currencyFormat.format(menu.harga)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Toggle ───
            Column(
              children: [
                Switch(
                  value: isAvailable,
                  onChanged: (_) => _handleToggle(index),
                  activeThumbColor: _kAvailableGreen,
                  inactiveThumbColor: _kUnavailableGrey,
                  inactiveTrackColor: Colors.grey[300],
                ),
                Text(
                  isAvailable ? 'Tersedia' : 'Habis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? _kAvailableGreen : _kUnavailableGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.fastfood, size: 32, color: Colors.grey[400]),
    );
  }
}