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

        // Tentukan Content-Type berdasarkan ekstensi agar Supabase tidak menolak file (Error 415)
        String contentType = 'image/jpeg'; // default
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

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(transactionRepoProvider).watchRecentTransactions();
});

// Helper function to calculate sum from a list of maps
double _calculateTotal(List<Map<String, dynamic>> data, bool Function(DateTime) filter) {
  return data.where((map) {
    final date = DateTime.parse(map['transaction_date']);
    return filter(date);
  }).fold<double>(0.0, (prev, element) => prev + (double.tryParse(element['total_amount'].toString()) ?? 0.0));
}

final monthlyTotalProvider = StreamProvider<double>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final now = DateTime.now();

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .map((data) => _calculateTotal(data, (date) => date.year == now.year && date.month == now.month));
});

final todayTotalProvider = StreamProvider<double>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final now = DateTime.now();

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .map((data) => _calculateTotal(data, (date) => 
          date.year == now.year && date.month == now.month && date.day == now.day));
});

final yesterdayTotalProvider = StreamProvider<double>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .map((data) => _calculateTotal(data, (date) => 
          date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day));
});

final weeklyTotalProvider = StreamProvider<double>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .map((data) => _calculateTotal(data, (date) => date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))));
});

final lastMonthTotalProvider = StreamProvider<double>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, 1);

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .map((data) => _calculateTotal(data, (date) => date.year == lastMonth.year && date.month == lastMonth.month));
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
