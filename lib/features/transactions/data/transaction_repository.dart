import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction_model.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // Mengambil semua transaksi user via stream (untuk dashboard & report)
  Stream<List<TransactionModel>> watchTransactions() {
    final userId = _supabase.auth.currentUser?.id;
    // Kita ambil data dari awal bulan lalu untuk mencakup semua statistik di dashboard
    final now = DateTime.now();
    final startRange = DateTime(now.year, now.month - 1, 1).toIso8601String();

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('transaction_date', ascending: false)
        .map((data) => data
            .map((map) => TransactionModel.fromMap(map))
            .where((t) => t.date.isAfter(DateTime.parse(startRange).subtract(const Duration(seconds: 1))))
            .toList());
  }

  // Insert transaksi baru dengan upload gambar
  Future<void> insertTransaction({
    required String date,
    required String merchantName,
    required double amount,
    required String category,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login!');

    String? imageUrl;

    try {
      if (imageBytes != null && imageExtension != null && imageExtension.isNotEmpty) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
        final filePath = '${user.id}/$fileName';

        String contentType = 'image/jpeg';
        if (imageExtension.toLowerCase() == 'png') contentType = 'image/png';
        if (imageExtension.toLowerCase() == 'webp') contentType = 'image/webp';
        if (imageExtension.toLowerCase() == 'gif') contentType = 'image/gif';

        await _supabase.storage.from('receipts').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: contentType,
              ),
            );

        imageUrl = _supabase.storage.from('receipts').getPublicUrl(filePath);
      }
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

  // Hapus transaksi
  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }
}

// Providers
final transactionRepoProvider = Provider((ref) => TransactionRepository());

// Single Source of Truth for Transactions
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepoProvider).watchTransactions();
});

// Derived Providers (Synchronous calculations from the stream)
final monthlyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final todayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final yesterdayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return transactions
      .where((t) => t.date.year == yesterday.year && t.date.month == yesterday.month && t.date.day == yesterday.day)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final weeklyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  
  return transactions
      .where((t) => t.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1))))
      .fold(0.0, (prev, t) => prev + t.amount);
});

final lastMonthTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();
  final lastMonthDate = DateTime(now.year, now.month - 1, 1);
  return transactions
      .where((t) => t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final filterDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final filterDate = ref.watch(filterDateProvider);

  return transactions.where((t) {
    return t.date.year == filterDate.year && t.date.month == filterDate.month;
  }).toList();
});

