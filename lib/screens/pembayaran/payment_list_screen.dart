import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/utils/constants.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final Set<String> _selectedPaymentIds = {};
  double _totalAmount = 0.0;

  void _onCheckboxChanged(bool? value, Payment payment) {
    setState(() {
      if (value == true) {
        _selectedPaymentIds.add(payment.id);
        _totalAmount += payment.amount;
      } else {
        _selectedPaymentIds.remove(payment.id);
        _totalAmount -= payment.amount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    final unpaidPayments = paymentProvider.payments
        .where((p) => p.status == PaymentStatus.unpaid || p.status == PaymentStatus.overdue)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayar SPP'),
        automaticallyImplyLeading: false,
      ),
      body: paymentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : unpaidPayments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Tidak ada tagihan yang harus dibayar saat ini.', textAlign: TextAlign.center),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: unpaidPayments.length,
                        itemBuilder: (context, index) {
                          final payment = unpaidPayments[index];
                          final isOverdue = payment.status == PaymentStatus.overdue;
                          
                          return Card(
                            color: _selectedPaymentIds.contains(payment.id) ? Colors.blue.withAlpha(50) : null,
                            child: CheckboxListTile(
                              value: _selectedPaymentIds.contains(payment.id),
                              onChanged: (value) => _onCheckboxChanged(value, payment),
                              title: Text('SPP ${payment.month} ${payment.year}'),
                              subtitle: Text(
                                'Jatuh Tempo: ${DateFormat('dd MMM yyyy', 'id_ID').format(payment.dueDate)}',
                                style: TextStyle(color: isOverdue ? Colors.red : null),
                              ),
                              secondary: Text(
                                formatCurrency.format(payment.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (unpaidPayments.isNotEmpty) _buildPaymentSummary(formatCurrency),
                  ],
                ),
    );
  }

  Widget _buildPaymentSummary(NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      child: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran:', style: TextStyle(fontSize: 16)),
                Text(
                  formatCurrency.format(_totalAmount),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.credit_card),
                label: const Text('Lanjutkan Pembayaran'),
                onPressed: _selectedPaymentIds.isEmpty ? null : _showPaymentDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Rekening Pembayaran'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Silakan transfer ke salah satu rekening berikut:'),
              const Divider(height: 20),
              _buildRekeningInfo(SchoolInfo.bca),
              _buildRekeningInfo(SchoolInfo.mandiri),
              _buildRekeningInfo(SchoolInfo.dana),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImageAndUpload();
            },
            child: const Text('Upload Bukti'),
          ),
        ],
      ),
    );
  }

  Widget _buildRekeningInfo(Map<String, String> info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info['bank']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('No: ${info['no']}'),
          Text('a.n: ${info['name']}'),
        ],
      ),
    );
  }

  Future<void> _pickImageAndUpload() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final paymentProvider = context.read<PaymentProvider>();
      final success = await paymentProvider.uploadProofForMultiplePayments(
        _selectedPaymentIds.toList(),
        imageFile,
        'Transfer Bank',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Bukti berhasil diupload. Menunggu konfirmasi admin.' : 'Gagal mengupload bukti.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          setState(() {
            _selectedPaymentIds.clear();
            _totalAmount = 0.0;
          });
        }
      }
    }
  }
}