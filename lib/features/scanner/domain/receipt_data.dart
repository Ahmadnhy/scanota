import 'dart:typed_data';

class ReceiptData {
  final String date;
  final String merchantName;
  final double totalAmount;
  final String category;
  final String imagePath;
  final Uint8List? imageBytes;

  ReceiptData({
    required this.date,
    required this.merchantName,
    required this.totalAmount,
    required this.category,
    required this.imagePath,
    this.imageBytes,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json, String imagePath, {Uint8List? imageBytes}) {
    return ReceiptData(
      date: json['tanggal'] ?? DateTime.now().toIso8601String().split('T')[0],
      merchantName: json['nama_merchant'] ?? 'Tidak Diketahui',
      totalAmount: (json['total_pengeluaran'] ?? 0).toDouble(),
      category: json['kategori'] ?? 'lainnya',
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
  }
}
