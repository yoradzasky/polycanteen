import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/seller_navbar.dart';

class FinanceWithdrawalItem {
  final String id;
  final DateTime date;
  final int amount;
  final String method;
  final String status;

  const FinanceWithdrawalItem({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
  });
}

/// CRITICAL ROLE-BASED ACCESS CONTROL
/// ⚠️ This screen is EXCLUSIVELY for 'pemilik' role
/// Pegawai/Employee must be BLOCKED from accessing this screen
/// 
/// Integration Pattern with State Management:
/// ```dart
/// // In your router or navigation guard:
/// final userRole = ref.watch(userStateProvider).role; // or equivalent
/// if (!FinanceReportScreen.isAccessAllowed(userRole)) {
///   return UnauthorizedFinanceScreen();
/// }
/// ```
class FinanceReportScreen extends StatelessWidget {
  FinanceReportScreen({
    super.key,
    this.totalRevenue = 1287500,
    List<FinanceWithdrawalItem>? withdrawals,
    this.userRole = 'pemilik',
  }) : withdrawals = withdrawals ?? _sampleWithdrawals;

  final int totalRevenue;
  final List<FinanceWithdrawalItem> withdrawals;
  final String userRole;

  /// ✅ ROLE VALIDATION HELPER
  /// Call this before navigating to FinanceReportScreen
  /// @param role The current user's role (case-insensitive)
  /// @return true if access is allowed, false if 'pegawai' or unauthorized
  static bool isAccessAllowed(String? role) {
    if (role == null || role.isEmpty) return false;
    final normalizedRole = role.toLowerCase().trim();
    // CRITICAL: Only 'pemilik' can access - 'pegawai' MUST be blocked
    return normalizedRole == 'pemilik';
  }

  static final List<FinanceWithdrawalItem> _sampleWithdrawals = [
    FinanceWithdrawalItem(
      id: 'WD-0001',
      date: DateTime(2026, 5, 31, 14, 20),
      amount: 450000,
      method: 'Transfer Bank',
      status: 'Berhasil',
    ),
    FinanceWithdrawalItem(
      id: 'WD-0002',
      date: DateTime(2026, 5, 29, 10, 45),
      amount: 325000,
      method: 'QRIS Settlement',
      status: 'Diproses',
    ),
    FinanceWithdrawalItem(
      id: 'WD-0003',
      date: DateTime(2026, 5, 26, 16, 10),
      amount: 512500,
      method: 'Transfer Bank',
      status: 'Berhasil',
    ),
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  @override
  Widget build(BuildContext context) {
    // ⚠️ CRITICAL ROLE-BASED ACCESS CONTROL
    // Block 'pegawai' from rendering this screen
    if (!isAccessAllowed(userRole)) {
      return const UnauthorizedFinanceScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildRevenueCard(context),
            const SizedBox(height: 20),
            _buildSectionHeader(),
            const SizedBox(height: 12),
            _buildWithdrawalList(context),
          ],
        ),
      ),
      bottomNavigationBar: SellerNavbar(
        currentIndex: 2,
        primaryColor: AppTheme.primaryBlue,
        onTap: (_) {},
        onQrTap: () {},
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.secondaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total Pendapatan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _currencyFormat.format(totalRevenue),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lightOrange.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Pesanan selesai',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Periode bulan ini',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Riwayat Pencairan',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryOrange,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('Lihat semua'),
        ),
      ],
    );
  }

  Widget _buildWithdrawalList(BuildContext context) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: withdrawals.length,
        separatorBuilder: (_, _) => const Divider(indent: 72, endIndent: 16),
        itemBuilder: (context, index) {
          final item = withdrawals[index];
          final isSuccess = item.status.toLowerCase() == 'berhasil';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.lightOrange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: AppTheme.primaryOrange,
              ),
            ),
            title: Text(
              _currencyFormat.format(item.amount),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${item.method} - ${_dateFormat.format(item.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppTheme.secondaryBlue.withValues(alpha: 0.12)
                    : AppTheme.lightOrange.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  color: isSuccess ? AppTheme.secondaryBlue : AppTheme.primaryOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ⚠️ UNAUTHORIZED ACCESS SCREEN
/// Shown when 'pegawai' or unauthorized users try to access FinanceReportScreen
/// This implements the CRITICAL ROLE-BASED PROTECTION requirement
class UnauthorizedFinanceScreen extends StatelessWidget {
  const UnauthorizedFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Akses Terbatas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Halaman Laporan Keuangan hanya dapat diakses oleh pemilik. Jika Anda adalah pemilik, silakan hubungi administrator.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
