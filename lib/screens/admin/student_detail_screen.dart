import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/profile_model.dart';
import 'package:sipatka/utils/app_theme.dart';

class StudentDetailScreen extends StatelessWidget {
  final Profile student;
  const StudentDetailScreen({super.key, required this.student});

  Future<List<Payment>> _getPaymentHistory() async {
    // Pastikan studentId tidak null sebelum melakukan query
    if (student.studentId == null) return [];

    final data = await supabase
        .from('payments')
        .select()
        .eq('student_id', student.studentId!)
        .order('due_date', ascending: false);
    
    return data.map((item) => Payment.fromMap(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student.studentName ?? 'Detail Siswa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.child_care_outlined, "Nama Siswa", student.studentName ?? '-'),
                    _buildInfoRow(Icons.class_outlined, "Kelas", student.className ?? '-'),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.person_outline, "Nama Wali", student.parentName ?? '-'),
                    _buildInfoRow(Icons.email_outlined, "Email Wali", student.email ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Riwayat Tagihan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            FutureBuilder<List<Payment>>(
              future: _getPaymentHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(padding: EdgeInsets.all(20.0), child: Text("Belum ada riwayat tagihan untuk siswa ini.")),
                  );
                }
                final payments = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentTile(payments[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 16),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, textAlign: TextAlign.end),
        ],
      ),
    );
  }
  
  Widget _buildPaymentTile(Payment payment) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    IconData icon;
    Color color;
    String text;

    switch (payment.status) {
      case 'paid':
        icon = Icons.check_circle;
        color = Colors.green;
        text = "Lunas";
        break;
      case 'pending':
        icon = Icons.pending;
        color = Colors.orange;
        text = "Pending";
        break;
      case 'overdue':
        icon = Icons.warning;
        color = Colors.red;
        text = "Terlambat";
        break;
      default: // unpaid
        icon = Icons.error;
        color = Colors.grey;
        text = "Belum Bayar";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text("SPP ${payment.month} ${payment.year}"),
        subtitle: Text("Jatuh Tempo: ${DateFormat('dd MMM yyyy', 'id_ID').format(payment.dueDate)}"),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(currencyFormat.format(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(text, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}