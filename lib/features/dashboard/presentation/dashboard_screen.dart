import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../transactions/data/transaction_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body:
          _selectedIndex == 0
              ? const HomeView()
              : const Center(child: Text('Halaman Laporan')),

      // Floating Action Button (Tombol Scan / +) di tengah
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scanner'),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar Custom
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab Home
              MaterialButton(
                minWidth: 40,
                onPressed: () => setState(() => _selectedIndex = 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_filled,
                      color:
                          _selectedIndex == 0
                              ? AppColors.primary
                              : Colors.grey.shade400,
                    ),
                    Text(
                      'Home',
                      style: TextStyle(
                        color:
                            _selectedIndex == 0
                                ? AppColors.primary
                                : Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight:
                            _selectedIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 40), // Spacer untuk FloatingActionButton
              // Tab Report
              MaterialButton(
                minWidth: 40,
                onPressed: () => setState(() => _selectedIndex = 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color:
                          _selectedIndex == 1
                              ? AppColors.primary
                              : Colors.grey.shade400,
                    ),
                    Text(
                      'Report',
                      style: TextStyle(
                        color:
                            _selectedIndex == 1
                                ? AppColors.primary
                                : Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight:
                            _selectedIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// TAMPILAN BERANDA (HOME VIEW)
// -----------------------------------------------------------------
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca data secara real-time dari Riverpod
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final totalSpending = ref.watch(monthlyTotalProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // HEADER & BALANCE SECTION (Area Atas dengan background soft)
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
            child: Column(
              children: [
                // Top Bar (Profile & Sapaan)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good Morning, Ahmad',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                            Text(
                              'Manage your finances today.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.darkText),
                      onPressed: () {
                        // Tambahkan logika logout ke auth repository
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Total Balance (Mines karena ini aplikasi pencatat pengeluaran)
                Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '-Rp ${totalSpending.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 16),

                // Mini Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+ Rp 0 this month',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      transactionsAsync.when(
                        data:
                            (data) => Text(
                              '${data.length} Transactions',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        loading:
                            () => const Text(
                              '...',
                              style: TextStyle(fontSize: 12),
                            ),
                        error:
                            (_, __) =>
                                const Text('-', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // WHITE CONTAINER (Area Bawah melengkung)
          Container(
            transform: Matrix4.translationValues(
              0,
              -20,
              0,
            ), // Tarik ke atas agar menimpa background
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Your Balance & Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Your Balance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      ],
                    ),
                    Text(
                      'Detail >',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Income & Expense Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceCard(
                        icon: Icons.payments_outlined,
                        title: 'Income',
                        amount: 'Rp 0',
                        iconColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBalanceCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Expenses',
                        amount:
                            'Rp ${totalSpending.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        iconColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Section: TODAY Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Total -Rp ${totalSpending.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // List View (Menggunakan Data Asli)
                transactionsAsync.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Belum ada pengeluaran hari ini.'),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          data.length > 5 ? 5 : data.length, // Tampilkan maks 5
                      separatorBuilder:
                          (context, index) => const Divider(
                            color: Color(0xFFF1F5F9),
                            height: 24,
                          ),
                      itemBuilder: (context, index) {
                        final t = data[index];
                        return Row(
                          children: [
                            // Icon Kategori
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getCategoryIcon(t.category),
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Nama Merchant & Label
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.merchantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildPillLabel(t.category.toUpperCase()),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Harga & Tanggal
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-Rp ${t.amount.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${t.date.day}/${t.date.month}/${t.date.year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                ),

                const SizedBox(height: 80), // Jarak aman untuk Bottom Nav Bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper untuk Kotak Income/Expense
  Widget _buildBalanceCard({
    required IconData icon,
    required String title,
    required String amount,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 12, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper untuk Label kategori (seperti "Food")
  Widget _buildPillLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper Ikon Kategori
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant;
      case 'transportasi':
        return Icons.directions_car;
      case 'belanja':
        return Icons.shopping_bag;
      case 'kesehatan':
        return Icons.health_and_safety;
      case 'tagihan':
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
