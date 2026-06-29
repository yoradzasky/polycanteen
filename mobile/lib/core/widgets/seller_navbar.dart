import 'package:flutter/material.dart';

class SellerNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onQrTap;
  final Color primaryColor;
  final String userRole;

  const SellerNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onQrTap,
    this.primaryColor = const Color(0xFF3949AB),
    this.userRole = 'pemilik',
  });

  @override
  Widget build(BuildContext context) {
    const Color inactiveColor = Color(0xFF9FA5C0);
    // Mendapatkan padding bawah dinamis untuk gesture bar
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      // Tinggi navbar 70 + ruang untuk gesture bar
      height: 70 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Base Navbar background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70 + bottomPadding,
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                      icon: Icons.assignment,
                      label: 'Kelola Menu',
                      index: 1,
                      isActive: currentIndex == 1,
                      activeColor: primaryColor,
                      inactiveColor: inactiveColor,
                    ),
                  ),
                  const Expanded(
                    child: SizedBox.shrink(),
                  ), // Empty space untuk QR button
                  if (userRole == 'pemilik')
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.show_chart,
                        label: 'Laporan',
                        index: 2,
                        isActive: currentIndex == 2,
                        activeColor: primaryColor,
                        inactiveColor: inactiveColor,
                      ),
                    )
                  else
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.history,
                        label: 'Riwayat',
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
            ),
          ),

          // Center Floating Button
          Positioned(
            top: -24,
            child: GestureDetector(
              onTap: onQrTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
              ),
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
