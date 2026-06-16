import 'package:flutter/material.dart';

class StudentNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color primaryColor;

  const StudentNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.primaryColor = const Color(0xFFF2994A),
  });

  @override
  Widget build(BuildContext context) {
    const Color inactiveColor = Color(0xFF9FA5C0);

    double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Tinggi navbar 70 + ruang untuk gesture bar
      height: 70 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              icon: Icons.home,
              label: 'Beranda',
              index: 0,
              isActive: currentIndex == 0,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.restaurant,
              label: 'Menu',
              index: 1,
              isActive: currentIndex == 1,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.shopping_bag,
              label: 'Pesanan',
              index: 2,
              isActive: currentIndex == 2,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.person,
              label: 'Profil',
              index: 3,
              isActive: currentIndex == 3,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final currentColor = isActive ? activeColor : inactiveColor;
    return InkWell(
      onTap: () => onTap(index),
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: isActive ? 0 : 4),
            child: Icon(icon, color: currentColor, size: isActive ? 28 : 24),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: currentColor,
              fontSize: isActive ? 12 : 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
