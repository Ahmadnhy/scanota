import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../scanner/presentation/scanner_provider.dart';
import 'widgets/report_view.dart';
import 'edit_profile_screen.dart';
import '../../transactions/domain/transaction_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  void _showTransactionMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  const SizedBox(height: 24),
                  _buildMenuButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan Receipt',
                    subtitle: 'Auto-extract data using AI',
                    onTap: () {
                      Navigator.pop(context);
                      _showScanOptions();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Manual Entry',
                    subtitle: 'Type transaction details yourself',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/manual-entry');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  void _showScanOptions() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ScanOptions',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select Source', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSquareOption(Icons.photo_library_rounded, 'Gallery', () {
                        Navigator.pop(context);
                        ref.read(scannerControllerProvider.notifier).processReceipt(ImageSource.gallery);
                      }),
                      _buildSquareOption(Icons.camera_alt_rounded, 'Camera', () {
                        Navigator.pop(context);
                        ref.read(scannerControllerProvider.notifier).processReceipt(ImageSource.camera);
                      }),
                      _buildSquareOption(Icons.file_present_rounded, 'Files', () {
                        Navigator.pop(context);
                        ref.read(scannerControllerProvider.notifier).processReceiptFromFile();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: ScaleTransition(scale: anim1, child: child));
      },
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(scannerControllerProvider, (previous, next) {
      if (previous is AsyncLoading && next is! AsyncLoading) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      next.when(
        data: (_) {
          if (previous is AsyncLoading && ref.read(scannedReceiptProvider) != null) {
            context.push('/validation');
          }
        },
        error: (e, _) => AppNotification.show(context, e.toString(), isError: true),
        loading: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withValues(alpha: 0.2),
            builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 40, height: 40,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
                          ),
                          const SizedBox(height: 24),
                          const Text('Scanning Receipt...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                          const SizedBox(height: 8),
                          Text('AI is extracting your transaction data', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _selectedIndex == 0 ? HomeView(onDetailPressed: () => setState(() => _selectedIndex = 1)) : const ReportView(),
        floatingActionButton: FloatingActionButton(
          onPressed: _showTransactionMenu,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 8,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                _buildNavItem(0, Icons.home_filled, 'Home'),
                const SizedBox(width: 40),
                _buildNavItem(1, Icons.bar_chart_rounded, 'Report'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.grey.shade400),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


// ... Rest of the HomeView class from previous turns ...
class HomeView extends ConsumerWidget {
  final VoidCallback onDetailPressed;
  const HomeView({super.key, required this.onDetailPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final monthlyTotalAsync = ref.watch(monthlyTotalProvider);
    final monthlyTotal = monthlyTotalAsync.value ?? 0.0;
    
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final username = user?.userMetadata?['username'] ?? 'User';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 24, right: 24, bottom: 40),
            decoration: BoxDecoration(gradient: AppColors.headerGradient),
            child: Column(
              children: [
                _buildHeaderTopBar(context, ref, username, avatarUrl),
                const SizedBox(height: 40),
                _buildBalanceDisplay(monthlyTotal, ref),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceAndIncomeCards(monthlyTotal),
                const SizedBox(height: 32),
                _buildTransactionSections(transactionsAsync, ref, context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTopBar(BuildContext context, WidgetRef ref, String username, String? avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Haloo, $username', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                Text('Manage your finances today.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.darkText),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Text('Logout', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(double totalSpending, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    return Column(
      children: [
        Text('Current Balance', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          '-Rp ${NumberFormat("#,###", "id_ID").format(totalSpending)}',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.darkText, letterSpacing: -1),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+ Rp 0 this month', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(width: 10),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              transactionsAsync.when(
                data: (data) => Text('${data.length} Transactions', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                loading: () => const Text('...', style: TextStyle(fontSize: 12)),
                error: (_, __) => const Text('-', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceAndIncomeCards(double totalSpending) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Your Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                const SizedBox(width: 8),
                _buildInfoIcon('Total saldo Anda saat ini setelah dikurangi pengeluaran.'),
              ],
            ),
            GestureDetector(
              onTap: onDetailPressed,
              child: const Text('Detail >', style: TextStyle(fontSize: 14, color: AppColors.darkText, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildBalanceCard(
                icon: Icons.payments_outlined,
                title: 'Income',
                amount: 'Rp 0',
                iconColor: AppColors.primary,
                info: 'Total pemasukan yang Anda catat bulan ini.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBalanceCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Expenses',
                amount: 'Rp ${NumberFormat("#,###", "id_ID").format(totalSpending)}',
                iconColor: AppColors.primary,
                info: 'Total pengeluaran yang Anda catat bulan ini.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionSections(AsyncValue<List<TransactionModel>> transactionsAsync, WidgetRef ref, BuildContext context) {
    return transactionsAsync.when(
      data: (data) {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        
        final todayData = data.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).toList();
        final yesterdayData = data.where((t) => t.date.year == yesterday.year && t.date.month == yesterday.month && t.date.day == yesterday.day).toList();
        
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        
        final weekData = data.where((t) {
          final tDate = DateTime(t.date.year, t.date.month, t.date.day);
          return (tDate.isAtSameMomentAs(startOfWeekDate) || tDate.isAfter(startOfWeekDate)) &&
                 !todayData.contains(t) && !yesterdayData.contains(t);
        }).toList();
        
        final monthData = data.where((t) {
          return t.date.year == now.year && t.date.month == now.month &&
                 !todayData.contains(t) && !yesterdayData.contains(t) && !weekData.contains(t);
        }).toList();

        if (data.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada transaksi.')));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('TODAY', todayData, ref, context, showEmpty: true),
            if (yesterdayData.isNotEmpty) const SizedBox(height: 24),
            _buildSection('YESTERDAY', yesterdayData, ref, context),
            if (weekData.isNotEmpty) const SizedBox(height: 24),
            _buildSection('THIS WEEK', weekData, ref, context),
            if (monthData.isNotEmpty) const SizedBox(height: 24),
            _buildSection('THIS MONTH', monthData, ref, context),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildSection(String title, List<TransactionModel> items, WidgetRef ref, BuildContext context, {bool showEmpty = false}) {
    if (items.isEmpty && !showEmpty) return const SizedBox.shrink();
    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 1)),
            Text('Total -Rp ${NumberFormat("#,###", "id_ID").format(total)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Belum ada transaksi hari ini.', style: TextStyle(color: AppColors.secondaryText)))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 32),
            itemBuilder: (context, index) => _buildTransactionItem(items[index], ref, context),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel t, WidgetRef ref, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
          child: Icon(_getCategoryIcon(t.category), color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
              const SizedBox(height: 8),
              _buildPillLabel(t.category.toUpperCase()),
            ],
          ),
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('-Rp ${NumberFormat("#,###", "id_ID").format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM, d yyyy').format(t.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to delete this transaction?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(transactionRepoProvider).deleteTransaction(t.id);
                          Navigator.pop(context);
                          AppNotification.show(context, 'Transaction deleted');
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.delete_sweep_rounded, size: 28, color: Colors.redAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoIcon(String message) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
    );
  }

  Widget _buildBalanceCard({required IconData icon, required String title, required String amount, required Color iconColor, required String info}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withValues(alpha: 0.2), iconColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              _buildInfoIcon(info),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
        ],
      ),
    );
  }

  Widget _buildPillLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.restaurant;
      case 'transportasi': return Icons.directions_car;
      case 'belanja': return Icons.shopping_bag;
      case 'kesehatan': return Icons.health_and_safety;
      case 'tagihan': return Icons.receipt_long;
      default: return Icons.account_balance_wallet;
    }
  }
}
