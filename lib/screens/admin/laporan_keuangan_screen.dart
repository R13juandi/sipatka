import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/utils/pdf_generator.dart';

class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({super.key});

  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen> {
  List<Map<String, dynamic>> _paidTransactions = [];
  List<Map<String, dynamic>> _unpaidTransactions = [];
  double _totalIncome = 0.0;
  bool _isLoading = true;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final TextEditingController _searchNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      var query = supabase.from('payments').select('*, students!inner(*, profiles!inner(*))');

      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      query = query.gte('due_date', startDate.toIso8601String()).lte('due_date', endDate.toIso8601String());
      
      if (_searchNameController.text.isNotEmpty) {
        query = query.ilike('students.full_name', '%${_searchNameController.text.trim()}%');
      }

      final List<Map<String, dynamic>> data = await query;
      
      final paidList = <Map<String, dynamic>>[];
      final unpaidList = <Map<String, dynamic>>[];
      double income = 0;

      for (var payment in data) {
        if (payment['status'] == 'paid') {
          paidList.add(payment);
          income += (payment['amount'] as num).toDouble();
        } else {
          unpaidList.add(payment);
        }
      }

      setState(() {
        _paidTransactions = paidList;
        _unpaidTransactions = unpaidList;
        _totalIncome = income;
      });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  void _cetakPdf() {
    if (_paidTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data lunas untuk dicetak.")));
      return;
    }
    PdfGenerator.generateAndPrintReport(
      paidPayments: _paidTransactions,
      totalIncome: _totalIncome,
      dateRange: DateTimeRange(
        start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        end: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // PERBAIKAN: UI LENGKAP DI SINI
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [IconButton(onPressed: _cetakPdf, icon: const Icon(Icons.print_outlined), tooltip: "Cetak Laporan PDF")],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Total Pendapatan Lunas (Sesuai Filter)', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(formatCurrency.format(_totalIncome), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(tabs: [Tab(text: 'Sudah Bayar'), Tab(text: 'Belum Bayar')]),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildPaymentList(_paidTransactions, formatCurrency, true),
                              _buildPaymentList(_unpaidTransactions, formatCurrency, false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          _buildFilterSection(),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<DateTime>(
              value: _selectedMonth,
              decoration: const InputDecoration(labelText: 'Pilih Bulan & Tahun'),
              items: List.generate(24, (index) {
                final date = DateTime(DateTime.now().year, DateTime.now().month - index, 1);
                return DropdownMenuItem(value: date, child: Text(DateFormat('MMMM yyyy', 'id_ID').format(date)));
              }),
              onChanged: (date) { if (date != null) setState(() => _selectedMonth = date);},
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchNameController,
              decoration: const InputDecoration(labelText: 'Cari Nama Siswa (Opsional)', prefixIcon: Icon(Icons.search)),
              onSubmitted: (_) => _fetchReport(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchReport,
                child: const Text('Terapkan Filter'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(List<Map<String, dynamic>> payments, NumberFormat formatCurrency, bool isPaid) {
    if (payments.isEmpty) return const Center(child: Text('Tidak ada data untuk filter ini.'));
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final student = payment['students'];
        final profile = student?['profiles'];
        return Card(
          child: ListTile(
            title: Text(student?['full_name'] ?? 'Siswa tidak ditemukan'),
            subtitle: Text('SPP ${payment['month']}\nWali: ${profile?['full_name'] ?? ''}'),
            isThreeLine: true,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(formatCurrency.format(payment['amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
                if (isPaid)
                  Text('Lunas: ${DateFormat('dd MMM', 'id_ID').format(DateTime.parse(payment['paid_date']))}', style: const TextStyle(fontSize: 12, color: Colors.green))
                else
                  Text('Jatuh Tempo: ${DateFormat('dd MMM', 'id_ID').format(DateTime.parse(payment['due_date']))}', style: const TextStyle(fontSize: 12, color: Colors.red))
              ],
            ),
          ),
        );
      },
    );
  }
}