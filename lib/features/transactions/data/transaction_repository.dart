import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction_model.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // Mengambil transaksi terbaru via stream
  Stream<List<TransactionModel>> watchRecentTransactions() {
    final userId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('transaction_date', ascending: false)
        .limit(10)
        .map((data) => data.map((map) => TransactionModel.fromMap(map)).toList());
  }

  // Mengambil total pengeluaran bulan ini
  Future<double> getTotalSpendingThisMonth() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toIso8601String();

    final response = await _supabase
        .from('transactions')
        .select('total_amount')
        .gte('transaction_date', firstDay);

    final List data = response as List;
    return data.fold<double>(0.0, (prev, element) => prev + (double.tryParse(element['total_amount'].toString()) ?? 0.0));
  }

  // Insert transaksi baru dengan upload gambar
  Future<void> insertTransaction({
    required String date,
    required String merchantName,
    required double amount,
    required String category,
    required Uint8List imageBytes,
    required String imageExtension,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login!');

    String? imageUrl;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
      final filePath = '${user.id}/$fileName';

      await _supabase.storage.from('receipts').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      imageUrl = _supabase.storage.from('receipts').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Gagal mengupload gambar struk: $e');
    }

    await _supabase.from('transactions').insert({
      'user_id': user.id,
      'transaction_date': date,
      'merchant_name': merchantName,
      'total_amount': amount,
      'category': category,
      'receipt_image_url': imageUrl,
    });
  }
}

// Providers
final transactionRepoProvider = Provider((ref) => TransactionRepository());

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepoProvider).watchRecentTransactions();
});

final monthlyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();

  return transactions
      .where((t) => t.date.month == now.month && t.date.year == now.year)
      .fold(0.0, (sum, item) => sum + item.amount);
});

final filterDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final filteredTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final filterDate = ref.watch(filterDateProvider);

  final firstDay = DateTime(filterDate.year, filterDate.month, 1).toIso8601String();
  final lastDay = DateTime(filterDate.year, filterDate.month + 1, 0, 23, 59, 59).toIso8601String();

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .order('transaction_date', ascending: false)
      .map((data) => data
          .where((map) {
            final date = DateTime.parse(map['transaction_date']);
            return date.isAfter(DateTime.parse(firstDay)) && date.isBefore(DateTime.parse(lastDay));
          })
          .map((map) => TransactionModel.fromMap(map))
          .toList());
});
