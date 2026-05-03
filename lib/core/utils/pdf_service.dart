import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/transactions/domain/transaction_model.dart';

class PdfService {
  static Future<void> generateTransactionReport(List<TransactionModel> transactions, DateTime date) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Laporan Pengeluaran - ${date.month}/${date.year}",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Merchant', 'Kategori', 'Total'],
            data: transactions.map((t) => [
              "${t.date.day}/${t.date.month}/${t.date.year}",
              t.merchantName,
              t.category.toUpperCase(),
              "Rp ${t.amount.toInt()}"
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.Divider(),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Total Keseluruhan: Rp ${transactions.fold(0.0, (sum, item) => sum + item.amount).toInt()}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
