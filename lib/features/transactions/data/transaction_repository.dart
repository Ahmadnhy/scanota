import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction_model.dart';

/// Safely extract a clean image extension, defaulting to 'jpg' if parsing fails.
String _safeExtension(String? rawExtension) {
  if (rawExtension == null || rawExtension.isEmpty) return 'jpg';
  // Strip query params and take only alphanumeric chars
  final cleaned = rawExtension.split('?').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  const validExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};
  if (validExts.contains(cleaned)) return cleaned;
  return 'jpg';
}

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // Mengambil semua transaksi user via SELECT query (reliable, tidak bergantung Realtime)
  Future<List<TransactionModel>> getTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Mengambil transaksi terbaru tanpa batasan tanggal agar struk lama yang di-scan tetap muncul
    final data = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false) // Urutkan berdasarkan waktu input
        .limit(100); // Batasi 100 transaksi terakhir agar performa tetap terjaga

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

    // Try uploading the image, but DON'T let upload failure block the transaction insert.
    if (imageBytes != null) {
      try {
        final ext = _safeExtension(imageExtension);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final filePath = '${user.id}/$fileName';

        String contentType = 'image/jpeg';
        if (ext == 'png') contentType = 'image/png';
        if (ext == 'webp') contentType = 'image/webp';
        if (ext == 'gif') contentType = 'image/gif';

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
      } catch (e) {
        // Log but don't throw — the transaction should still be saved.
        debugPrint('[TransactionRepo] Image upload failed (will save without image): $e');
      }
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

  // Update transaksi
  Future<void> updateTransaction({
    required String id,
    required String date,
    required String merchantName,
    required double amount,
    required String category,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login!');

    await _supabase.from('transactions').update({
      'transaction_date': date,
      'merchant_name': merchantName,
      'total_amount': amount,
      'category': category,
    }).eq('id', id);
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
      .where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final yearlyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.createdAt.year == now.year)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final todayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final yesterdayTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return transactions
      .where((t) => t.createdAt.year == yesterday.year && t.createdAt.month == yesterday.month && t.createdAt.day == yesterday.day)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final weeklyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  
  return transactions
      .where((t) => t.createdAt.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1))))
      .fold(0.0, (prev, t) => prev + t.amount);
});

final lastMonthTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final lastMonthDate = DateTime(now.year, now.month - 1, 1);
  return transactions
      .where((t) => t.createdAt.year == lastMonthDate.year && t.createdAt.month == lastMonthDate.month)
      .fold(0.0, (prev, t) => prev + t.amount);
});

final filterDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final filterDate = ref.watch(filterDateProvider);

  return transactions.where((t) {
    return t.createdAt.year == filterDate.year && t.createdAt.month == filterDate.month;
  }).toList();
});

