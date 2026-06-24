import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/finance_service.dart';

class FinanceReportScreen extends StatefulWidget {
  const FinanceReportScreen({Key? key}) : super(key: key);

  @override
  State<FinanceReportScreen> createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().fetchFinanceData();
    });
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FinanceProvider>().fetchFinanceData();
            },
          )
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!.replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = provider.summary;
          final history = provider.history;

          return RefreshIndicator(
            onRefresh: () => provider.fetchFinanceData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- KARTU AGREGASI PENDAPATAN ---
                if (summary != null) ...[
                  _buildSummaryCard(
                    title: 'Pendapatan Hari Ini',
                    amount: summary['daily_revenue'] ?? 0,
                    color: Colors.green,
                    icon: Icons.today,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    title: 'Pendapatan Bulan Ini',
                    amount: summary['monthly_revenue'] ?? 0,
                    color: Colors.blue,
                    icon: Icons.calendar_month,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    title: 'Total Pendapatan',
                    amount: summary['total_revenue'] ?? 0,
                    color: Colors.purple,
                    icon: Icons.account_balance_wallet,
                  ),
                ],
                const SizedBox(height: 24),
                
                // --- DAFTAR RIWAYAT TRANSAKSI ---
                const Text(
                  'Riwayat Transaksi (Selesai)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                if (history.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Belum ada transaksi yang selesai.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final date = DateTime.parse(item['updated_at']).toLocal();
                      final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(date);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        elevation: 2,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text('Pesanan #${item['id']}'),
                          subtitle: Text('Pelanggan: ${item['mahasiswa']?['nama'] ?? 'Tidak diketahui'}\n$formattedDate'),
                          isThreeLine: true,
                          trailing: Text(
                            formatCurrency(double.parse(item['total_harga'].toString())),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required dynamic amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(double.parse(amount.toString())),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* 
======================================================================
CONTOH IMPLEMENTASI KONDISIONAL NAVIGASI BERDASARKAN ROLE DI DRAWER
======================================================================

Pastikan Anda telah menyimpan `role` saat user login ke SharedPreferences.

```dart
// Contoh di dalam Drawer atau Bottom Navigation Bar
Widget buildDrawer(BuildContext context, String role) {
  return Drawer(
    child: ListView(
      children: [
        // Menu lainnya...
        ListTile(
          title: Text('Kelola Menu'),
          onTap: () { ... },
        ),
        
        // --- LOGIKA KONDISIONAL ---
        // Sembunyikan sama sekali jika role bukan 'pemilik'
        if (role == 'pemilik') 
          ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Laporan Keuangan'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => FinanceProvider(),
                    child: const FinanceReportScreen(),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
```
======================================================================
*/
