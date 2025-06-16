import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/admin_provider.dart';

class ConfirmPaymentsScreen extends StatefulWidget {
  const ConfirmPaymentsScreen({super.key});

  @override
  State<ConfirmPaymentsScreen> createState() => _ConfirmPaymentsScreenState();
}

class _ConfirmPaymentsScreenState extends State<ConfirmPaymentsScreen> {
  late Future<List<Payment>> _pendingPaymentsFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() {
    final future = context.read<AdminProvider>().getPendingPaymentsWithStudentInfo();
    setState(() {
      _pendingPaymentsFuture = future;
    });
    return future;
  }

  Future<void> _handlePayment(String paymentId, String newStatus) async {
    final success = await context.read<AdminProvider>().updatePaymentStatus(paymentId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status pembayaran berhasil diupdate.' : 'Gagal mengupdate status.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        _loadPendingPayments(); // Refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: RefreshIndicator(
        onRefresh: _loadPendingPayments,
        child: FutureBuilder<List<Payment>>(
          future: _pendingPaymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada pembayaran yang perlu dikonfirmasi.'));
            }
            final payments = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  child: ListTile(
                    title: Text(payment.studentName ?? 'Siswa tidak ditemukan'),
                    subtitle: Text('SPP ${payment.month} ${payment.year}\nOleh: ${payment.parentName ?? ''}'),
                    isThreeLine: true,
                    trailing: Text(formatCurrency.format(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _showConfirmationDialog(context, payment),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi: ${payment.month}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bukti Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (payment.proofUrl != null)
              Center(
                child: Image.network(
                  payment.proofUrl!,
                  height: 250,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null ? child : const CircularProgressIndicator(),
                  errorBuilder: (context, error, stack) => const Text('Gagal memuat gambar.'),
                ),
              )
            else
              const Text('Tidak ada bukti pembayaran.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handlePayment(payment.id, 'unpaid');
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handlePayment(payment.id, 'paid');
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }
}