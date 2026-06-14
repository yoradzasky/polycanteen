import 'package:flutter/material.dart';
import '../../student/home/screens/home_screen.dart';
import '../../student/profile/screens/profile_screen.dart';
import '../../student/canteen/screens/canteen_list_screen.dart';
import '../widgets/student_navbar.dart';

class StudentMainLayout extends StatefulWidget {
  final String userRole; // 1. Tambahkan variabel untuk menyimpan role

  const StudentMainLayout({
    super.key,
    required this.userRole, // 2. Jadikan role sebagai parameter wajib
  });

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CanteenListScreen(),
    const Center(child: Text("Halaman Pesanan Belum Tersedia")),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // 3. Logika kondisional: Tampilkan jika mahasiswa, hilangkan jika bukan
      bottomNavigationBar: widget.userRole == 'mahasiswa'
          ? StudentNavbar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            )
          : null, // Menggunakan null agar Scaffold tidak menyisakan ruang kosong di bawah
    );
  }
}