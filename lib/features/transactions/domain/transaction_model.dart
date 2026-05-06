class TransactionModel {
  final String id;
  final DateTime date;
  final DateTime createdAt;
  final String merchantName;
  final double amount;
  final String category;
  final String? imageUrl;

  TransactionModel({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.merchantName,
    required this.amount,
    required this.category,
    this.imageUrl,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      date: DateTime.parse(map['transaction_date']).toLocal(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']).toLocal() : DateTime.parse(map['transaction_date']).toLocal(),
      merchantName: map['merchant_name'],
      amount: (map['total_amount'] as num).toDouble(),
      category: map['category'],
      imageUrl: map['receipt_image_url'],
    );
  }
}
