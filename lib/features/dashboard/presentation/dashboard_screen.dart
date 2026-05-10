import 'package:flutter/material.dart';
import '../../../core/utils/category_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import '../../transactions/data/transaction_repository.dart';
import './widgets/report_view.dart';
import './widgets/transaction_detail_sheet.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../scanner/presentation/scanner_provider.dart';
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
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
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
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
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
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Source',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSquareOption(
                        Icons.photo_library_rounded,
                        'Gallery',
                        () {
                          Navigator.pop(context);
                          ref
                              .read(scannerControllerProvider.notifier)
                              .processReceipt(ImageSource.gallery);
                        },
                      ),
                      _buildSquareOption(
                        Icons.camera_alt_rounded,
                        'Camera',
                        () {
                          Navigator.pop(context);
                          ref
                              .read(scannerControllerProvider.notifier)
                              .processReceipt(ImageSource.camera);
                        },
                      ),
                      _buildSquareOption(
                        Icons.file_present_rounded,
                        'Files',
                        () {
                          Navigator.pop(context);
                          ref
                              .read(scannerControllerProvider.notifier)
                              .processReceiptFromFile();
                        },
                      ),
                    ],
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
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
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
          if (previous is AsyncLoading &&
              ref.read(scannedReceiptProvider) != null) {
            context.push('/validation');
          }
        },
        error: (e, _) {
          if (e.toString() == 'QUOTA_LIMIT') {
            _showQuotaLimitDialog();
          } else {
            AppNotification.show(context, e.toString(), isError: true);
          }
        },
        loading: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withValues(alpha: 0.2),
            builder:
                (context) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      strokeWidth: 6,
                                      value: 1,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 6,
                                    ),
                                  ),
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Scanning Receipt',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: AppColors.darkText,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'AI is extracting your transaction data\nto make things easier for you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.grey.shade600,
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
        },
      );
    });

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body:
            _selectedIndex == 0
                ? HomeView(
                  onDetailPressed: () => setState(() => _selectedIndex = 1),
                )
                : const ReportView(),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _showTransactionMenu,
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
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

  void _showQuotaLimitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Daily Limit Reached',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The AI scanning limit has been reached for today. You can still add transactions manually!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/manual-entry');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Manual Entry',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class HomeView extends ConsumerWidget {
  final VoidCallback onDetailPressed;
  const HomeView({super.key, required this.onDetailPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    ref.watch(realtimeTransactionListenerProvider);

    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final username = user?.userMetadata?['username'] ?? 'User';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Stack(
      children: [
        // Header Gradient Background (Extended)
        Container(
          height: 400,
          decoration: BoxDecoration(gradient: AppColors.headerGradient),
        ),
        SingleChildScrollView(
          child: Column(
            children: [
              // Header Content
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 24,
                  right: 24,
                  bottom: 40,
                ),
                child: Column(
                  children: [
                    _buildHeaderTopBar(
                      context,
                      ref,
                      username,
                      avatarUrl,
                      isDark: false,
                    ),
                    const SizedBox(height: 40),
                    _buildBalanceDisplay(monthlyTotal, ref, isDark: false),
                  ],
                ),
              ),
              // Main Content Area
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
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
        ),
      ],
    );
  }

  Widget _buildHeaderTopBar(
    BuildContext context,
    WidgetRef ref,
    String username,
    String? avatarUrl, {
    bool isDark = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? Colors.white24 : AppColors.primary,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child:
                    avatarUrl == null
                        ? Icon(
                          Icons.person,
                          color: isDark ? Colors.white : Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $username',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkText,
                  ),
                ),
                Text(
                  'Manage your finances today.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Are you sure you want to log out?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () async {
                                    final router = GoRouter.of(context);
                                    Navigator.pop(context); // Close dialog
                                    await ref
                                        .read(authRepositoryProvider)
                                        .signOut();
                                    router.go('/welcome');
                                  },
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(
    double totalSpending,
    WidgetRef ref, {
    bool isDark = false,
  }) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final yearlyTotal = ref.watch(yearlyTotalProvider);

    return Column(
      children: [
        Text(
          'Current Expenses',
          style: TextStyle(
            color:
                isDark
                    ? Colors.white70
                    : AppColors.darkText.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.darkText,
              letterSpacing: -1,
            ),
            children: [
              TextSpan(
                text: '-Rp ',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
              TextSpan(
                text: NumberFormat("#,###", "id_ID").format(totalSpending),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white24 : Colors.white),
          ),
          child: Row(
            mainAxisSize: minAxisSize,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '- Rp ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${NumberFormat("#,###", "id_ID").format(yearlyTotal)} this year',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppColors.darkText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              transactionsAsync.when(
                data:
                    (data) => Text(
                      '${data.length} Transactions',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.darkText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                loading:
                    () => Text(
                      '...',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.darkText,
                        fontSize: 12,
                      ),
                    ),
                error:
                    (_, __) => Text(
                      '-',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.darkText,
                        fontSize: 12,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for Row mainAxisSize
  static const MainAxisSize minAxisSize = MainAxisSize.min;

  Widget _buildBalanceAndIncomeCards(double totalSpending) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Your Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(width: 8),
                _buildInfoIcon(
                  'Your current total balance after deducting expenses.',
                ),
              ],
            ),
            GestureDetector(
              onTap: onDetailPressed,
              child: const Text(
                'Detail >',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                iconColor: Colors.green,
                info: 'Total income recorded this month.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBalanceCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Expenses',
                amount:
                    'Rp ${NumberFormat("#,###", "id_ID").format(totalSpending)}',
                iconColor: Colors.redAccent,
                info: 'Total expenses recorded this month.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String title,
    required String amount,
    required Color iconColor,
    required String info,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 8),
                _buildInfoIcon(info),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(String message, {Color color = Colors.grey}) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      child: Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: color.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTransactionSections(
    AsyncValue<List<TransactionModel>> transactionsAsync,
    WidgetRef ref,
    BuildContext context,
  ) {
    return transactionsAsync.when(
      data: (data) {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final todayData =
            data
                .where(
                  (t) =>
                      t.createdAt.year == now.year &&
                      t.createdAt.month == now.month &&
                      t.createdAt.day == now.day,
                )
                .toList();
        final yesterdayData =
            data
                .where(
                  (t) =>
                      t.createdAt.year == yesterday.year &&
                      t.createdAt.month == yesterday.month &&
                      t.createdAt.day == yesterday.day,
                )
                .toList();

        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );

        final weekData =
            data.where((t) {
              final tDate = DateTime(
                t.createdAt.year,
                t.createdAt.month,
                t.createdAt.day,
              );
              return (tDate.isAtSameMomentAs(startOfWeekDate) ||
                      tDate.isAfter(startOfWeekDate)) &&
                  !todayData.contains(t) &&
                  !yesterdayData.contains(t);
            }).toList();

        final monthData =
            data.where((t) {
              return t.createdAt.year == now.year &&
                  t.createdAt.month == now.month &&
                  !todayData.contains(t) &&
                  !yesterdayData.contains(t) &&
                  !weekData.contains(t);
            }).toList();

        final olderData =
            data.where((t) {
              return !todayData.contains(t) &&
                  !yesterdayData.contains(t) &&
                  !weekData.contains(t) &&
                  !monthData.contains(t);
            }).toList();

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
            if (olderData.isNotEmpty) const SizedBox(height: 24),
            _buildSection('OLDER', olderData, ref, context),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildSection(
    String title,
    List<TransactionModel> items,
    WidgetRef ref,
    BuildContext context, {
    bool showEmpty = false,
  }) {
    if (items.isEmpty && !showEmpty) return const SizedBox.shrink();
    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                letterSpacing: 1,
              ),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'Total -Rp ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: NumberFormat("#,###", "id_ID").format(total)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No transactions today.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder:
                (context, index) =>
                    const Divider(color: Color(0xFFF1F5F9), height: 32),
            itemBuilder:
                (context, index) =>
                    _buildTransactionItem(items[index], ref, context),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(
    TransactionModel t,
    WidgetRef ref,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () => _showTransactionDetails(context, t, ref),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: CategoryUtils.getColor(
                  t.category,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                CategoryUtils.getIcon(t.category),
                color: CategoryUtils.getColor(t.category),
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 8),
                  _buildPillLabel(
                    CategoryUtils.getUiName(t.category).toUpperCase(),
                    CategoryUtils.getColor(t.category),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.darkText,
                    ),
                    children: [
                      TextSpan(
                        text: '-Rp ',
                        style: const TextStyle(
                          fontSize: 16, // Matched to amount font size
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText, // Removed alpha
                        ),
                      ),
                      TextSpan(
                        text: NumberFormat("#,###", "id_ID").format(t.amount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM, d yyyy').format(t.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionModel t,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TransactionDetailSheet(transaction: t),
    );
  }

  Widget _buildPillLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
