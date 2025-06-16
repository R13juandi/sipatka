import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/providers/payment_provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    Payment? nextUnpaidBill;
    try {
      nextUnpaidBill = paymentProvider.payments.firstWhere(
        (p) => p.status == PaymentStatus.unpaid || p.status == PaymentStatus.overdue);
    } catch (e) {
      nextUnpaidBill = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${authProvider.userName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
            Text(authProvider.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Refresh Data",
            onPressed: () => paymentProvider.fetchPayments(),
            icon: const Icon(Icons.refresh_outlined),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => paymentProvider.fetchPayments(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tagihan SPP Selanjutnya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (paymentProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (nextUnpaidBill == null)
                Card(
                  color: Colors.green.shade50,
                  child: const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Semua Tagihan Lunas!', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Terima kasih telah membayar tepat waktu.'),
                  )
                )
              else
                Card(
                  elevation: 4,
                  surfaceTintColor: nextUnpaidBill.status == PaymentStatus.overdue ? Colors.red.shade50 : Colors.orange.shade50,
                  child: ListTile(
                    leading: Icon(
                      Icons.receipt_long,
                      color: nextUnpaidBill.status == PaymentStatus.overdue ? Colors.red.shade700 : Colors.orange.shade700,
                      size: 40,
                    ),
                    title: Text('SPP Bulan ${nextUnpaidBill.month} ${nextUnpaidBill.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Jatuh tempo: ${DateFormat('dd MMMM yyyy', 'id_ID').format(nextUnpaidBill.dueDate)}'),
                    trailing: Text(
                      formatCurrency.format(nextUnpaidBill.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}