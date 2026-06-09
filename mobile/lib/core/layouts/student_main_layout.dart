import 'package:flutter/material.dart';

import '../widgets/student_navbar.dart';
import '../../student/order/screens/order_screen.dart';

class StudentMainLayout extends StatefulWidget {
  const StudentMainLayout({super.key});

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text("Halaman Beranda Belum Tersedia")),
    const Center(child: Text("Halaman Menu Belum Tersedia")),
    const OrderScreen(),
    const Center(child: Text("Halaman Profil Belum Tersedia")),
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
      bottomNavigationBar: StudentNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
