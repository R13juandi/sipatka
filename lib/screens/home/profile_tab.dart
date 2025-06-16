import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/screens/communication/chat_screen.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:sipatka/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) { // PERBAIKAN: 'context' berasal dari sini
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
            onPressed: () => _showLogoutDialog(context),
          )
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle("Data Siswa"),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.child_care_outlined, "Nama Siswa", profile.studentName ?? '-'),
                        _buildInfoRow(Icons.class_outlined, "Kelas", profile.className ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Data Wali"),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline, "Nama Wali", profile.parentName ?? '-'),
                        _buildInfoRow(Icons.email_outlined, "Email", profile.email ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Bantuan & Informasi"),
                Card(
                  child: Column(
                    children: [
                       ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                        title: const Text("Live Chat dengan Admin"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        title: const Text("Detail Informasi Sekolah"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showSchoolInfoDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ... sisa fungsi helper di bawah ini sudah benar ...
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _showSchoolInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(SchoolInfo.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSchoolInfoRow(context, "Alamat:", SchoolInfo.address), // PERBAIKAN: Kirim context
                _buildSchoolInfoRow(context, "Kepala Sekolah:", SchoolInfo.principal),
                _buildSchoolInfoRow(context, "Operator:", SchoolInfo.operator),
                _buildSchoolInfoRow(context, "NPSN:", SchoolInfo.npsn),
                _buildSchoolInfoRow(context, "Akreditasi:", SchoolInfo.accreditation),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text("Lihat Peta"),
              onPressed: () async {
                final url = Uri.parse("https://maps.google.com/?q=${Uri.encodeComponent(SchoolInfo.address)}");
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSchoolInfoRow(BuildContext context, String label, String value) { // PERBAIKAN: Terima context
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style, // PERBAIKAN: Gunakan context yang diterima
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if(context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Keluar'),
            )
        ],
    ));
  }
}