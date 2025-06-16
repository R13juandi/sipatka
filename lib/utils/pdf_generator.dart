import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndPrintReport({
    required List<Map<String, dynamic>> paidPayments,
    required double totalIncome,
    required DateTimeRange dateRange,
  }) async {
    final pdf = pw.Document();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final formatDate = DateFormat('dd MMMM yyyy', 'id_ID');
    
    // Load font
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Laporan Keuangan SIPATKA', style: pw.TextStyle(font: boldFont, fontSize: 18)),
                  pw.Text('TK An-Naafi\'Nur', style: pw.TextStyle(font: font)),
                ],
              ),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Periode Laporan:', style: pw.TextStyle(font: boldFont)),
                pw.Text('${formatDate.format(dateRange.start)} - ${formatDate.format(dateRange.end)}', style: pw.TextStyle(font: font)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Pendapatan Lunas:', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.Text(formatCurrency.format(totalIncome), style: pw.TextStyle(font: boldFont, fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 20),
            _buildTable(paidPayments, formatCurrency, font, boldFont),
            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                   pw.Text('Tangerang, ${formatDate.format(DateTime.now())}', style: pw.TextStyle(font: font)),
                   pw.SizedBox(height: 60),
                   pw.Text('Muhammad Rizqi Djuwandi', style: pw.TextStyle(font: boldFont, decoration: pw.TextDecoration.underline)),
                   pw.Text('Kepala Sekolah', style: pw.TextStyle(font: font)),
                ]
              )
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildTable(
      List<Map<String, dynamic>> payments, NumberFormat formatCurrency, pw.Font font, pw.Font boldFont) {
    final headers = ['Tanggal Bayar', 'Nama Siswa', 'Bulan SPP', 'Jumlah'];

    final data = payments.map((payment) {
      final profile = payment['profiles'];
      return [
        DateFormat('dd-MM-yyyy').format(DateTime.parse(payment['paid_date'])),
        profile?['student_name'] ?? 'N/A',
        payment['month'],
        formatCurrency.format(payment['amount']),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      cellStyle: pw.TextStyle(font: font),
    );
  }
}