import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/payment_provider.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) { // PERBAIKAN: Typo diperbaiki di sini
    final paymentProvider = context.watch<PaymentProvider>();
    final payments = paymentProvider.payments;
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    double totalPaid = payments
        .where((p) => p.status == PaymentStatus.paid)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pembayaran"),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => paymentProvider.fetchPayments(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Theme.of(context).primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Text("Total Terbayar (1 Tahun Ajaran)", style: TextStyle(color: Colors.white70)),
                        Text(formatCurrency.format(totalPaid), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: paymentProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : payments.isEmpty
                      ? const Center(child: Text("Tidak ada riwayat pembayaran."))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return _buildHistoryTile(payment, formatCurrency);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Payment payment, NumberFormat formatter) {
    IconData icon;
    Color color;
    String text;

    switch (payment.status) {
      case PaymentStatus.paid:
        icon = Icons.check_circle;
        color = Colors.green;
        text = "Lunas pada ${DateFormat('dd MMM yy', 'id_ID').format(payment.paidDate!)}";
        break;
      case PaymentStatus.pending:
        icon = Icons.pending;
        color = Colors.orange;
        text = "Menunggu Konfirmasi";
        break;
      case PaymentStatus.overdue:
        icon = Icons.warning;
        color = Colors.red;
        text = "Terlambat";
        break;
      default: // unpaid
        icon = Icons.error_outline;
        color = Colors.grey;
        text = "Belum Dibayar";
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text("SPP ${payment.month} ${payment.year}"),
        subtitle: Text(text),
        trailing: Text(formatter.format(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}