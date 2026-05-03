import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/transactions/data/transaction_repository.dart';
import '../../../core/utils/pdf_service.dart';
import 'widgets/category_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const HistoryView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.teal.shade900,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.grid_view_rounded, 0, "Beranda"),
            GestureDetector(
              onTap: () => context.push('/scanner'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.teal, size: 30),
              ),
            ),
            _navItem(Icons.history_rounded, 1, "Riwayat"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String label) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 28),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: 4,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            )
        ],
      ),
    );
  }
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final totalSpending = ref.watch(monthlyTotalProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 80,
          title: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.teal, Color(0xFF00796B)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pengeluaran Bulan Ini", style: TextStyle(color: Colors.white70)),
                      Text(
                        "Rp ${totalSpending.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Alokasi Dana", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: transactionsAsync.when(
                    data: (data) => data.isEmpty
                        ? const Center(child: Text("Belum ada data"))
                        : CategoryChart(transactions: data),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),
                ),
                const SizedBox(height: 30),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Terakhir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                transactionsAsync.when(
                  data: (data) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length > 5 ? 5 : data.length,
                    itemBuilder: (context, index) {
                      final t = data[index];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(_getCategoryIcon(t.category))),
                        title: Text(t.merchantName),
                        subtitle: Text(t.date.toString().split(' ')[0]),
                        trailing: Text("-Rp ${t.amount.toInt()}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.restaurant;
      case 'transportasi': return Icons.directions_car;
      case 'belanja': return Icons.shopping_bag;
      default: return Icons.account_balance_wallet;
    }
  }
}

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(filterDateProvider);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Laporan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              transactionsAsync.whenData((data) {
                if (data.isNotEmpty) {
                  PdfService.generateTransactionReport(data, selectedDate);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.teal),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      ref.read(filterDateProvider.notifier).state = picked;
                    }
                  },
                  child: Text(
                    "${_getMonthName(selectedDate.month)} ${selectedDate.year}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (data) => data.isEmpty
                ? const Center(child: Text("Tidak ada transaksi di bulan ini."))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final t = data[index];
                      return Card(
                        child: ListTile(
                          title: Text(t.merchantName),
                          subtitle: Text("${t.date.day} ${_getMonthName(t.date.month)}"),
                          trailing: Text("Rp ${t.amount.toInt()}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                    "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
    return months[month - 1];
  }
}
