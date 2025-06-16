import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/screens/admin/confirm_payments_screen.dart';
import 'package:sipatka/screens/admin/laporan_keuangan_screen.dart';
import 'package:sipatka/screens/admin/manage_students_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Fungsi untuk mengambil jumlah pembayaran yang pending
  Future<int> _getPendingCount() async {
    try {
      final res = await supabase.from('payments').count(CountOption.exact).eq('status', 'pending');
      return res;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            title: 'Manajemen Siswa',
            icon: Icons.people_alt_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStudentsScreen())),
          ),
          FutureBuilder<int>(
            future: _getPendingCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _buildMenuCard(
                context,
                title: 'Konfirmasi Pembayaran',
                icon: Icons.check_circle_outline,
                notificationCount: count,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfirmPaymentsScreen())),
              );
            },
          ),
          _buildMenuCard(
            context,
            title: 'Laporan Keuangan',
            icon: Icons.bar_chart_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanKeuanganScreen())),
          ),
          _buildMenuCard(
            context,
            title: 'Buat Akun Siswa',
            icon: Icons.person_add_alt_1_outlined,
            onTap: () => Navigator.pushNamed(context, '/admin_create_student'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, int? notificationCount}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 50, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (notificationCount != null && notificationCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(onPressed: () async {
                await context.read<AuthProvider>().logout();
                if(context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }, child: const Text('Keluar'))
        ],
    ));
  }
}