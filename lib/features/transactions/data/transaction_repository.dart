import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction_model.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // Mengambil semua transaksi user via SELECT query (reliable, tidak bergantung Realtime)
  Future<List<TransactionModel>> getTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Kita ambil data dari awal bulan lalu untuk mencakup semua statistik di dashboard
    final now = DateTime.now();
    final startRange = DateTime(now.year, now.month - 1, 1).toIso8601String();

    final data = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('transaction_date', startRange)
        .order('transaction_date', ascending: false);

    return data.map((map) => TransactionModel.fromMap(map)).toList();
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

// ============================================================================
// SINGLE SOURCE OF TRUTH — FutureProvider berbasis SELECT query
// Lebih reliable dari StreamProvider karena tidak bergantung pada Supabase
// Realtime yang harus di-enable di server. Setiap kali di-invalidate,
// langsung fetch data terbaru dari database.
// ============================================================================
final transactionsProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  // Keep alive agar tidak di-dispose saat tidak ada listener sementara
  ref.keepAlive();
  return ref.watch(transactionRepoProvider).getTransactions();
});

// ============================================================================
// REALTIME LISTENER — Optional, auto-refresh jika Realtime aktif di Supabase
// Jika Realtime tidak di-enable di tabel, listener ini tidak akan
// menerima event, tapi app tetap berjalan normal karena pakai FutureProvider.
// ============================================================================
final realtimeTransactionListenerProvider = Provider<void>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  final channel = supabase.channel('transactions_realtime');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          // Setiap ada INSERT/UPDATE/DELETE dari perangkat lain,
          // invalidate provider agar UI langsung refresh
          ref.invalidate(transactionsProvider);
        },
      )
      .subscribe();

  // Cleanup: unsubscribe channel saat provider di-dispose
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
});

// Derived Providers (Synchronous calculations from the fetched data)
final monthlyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final todayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final yesterdayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return transactions
      .where((t) => t.date.year == yesterday.year && t.date.month == yesterday.month && t.date.day == yesterday.day)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final weeklyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  
  return transactions
      .where((t) => t.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1))))
      .fold(0.0, (prev, t) => prev + t.amount);
});

final lastMonthTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final lastMonthDate = DateTime(now.year, now.month - 1, 1);
  return transactions
      .where((t) => t.date.year == lastMonthDate.year && t.date.month == lastMonthDate.month)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final filterDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final filterDate = ref.watch(filterDateProvider);

  return transactions.where((t) {
    return t.date.year == filterDate.year && t.date.month == filterDate.month;
  }).toList();
});

