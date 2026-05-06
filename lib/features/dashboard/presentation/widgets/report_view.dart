import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction_model.dart';
import './transaction_detail_sheet.dart';

class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'makanan', 'transportasi', 'belanja', 'tagihan', 'kesehatan', 'lainnya'];

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final todayTotal = ref.watch(todayTotalProvider);
    final yesterdayTotal = ref.watch(yesterdayTotalProvider);
    final weeklyTotal = ref.watch(weeklyTotalProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final lastMonthTotal = ref.watch(lastMonthTotalProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Analytics Report', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: transactionsAsync.when(
          data: (data) {
            // Filtering logic
            final filteredData = data.where((t) {
              final matchesSearch = t.merchantName.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesCategory = _selectedCategory == 'All' || t.category.toLowerCase() == _selectedCategory.toLowerCase();
              return matchesSearch && matchesCategory;
            }).toList();

            // Sectioned logic
            final now = DateTime.now();
            final yesterday = now.subtract(const Duration(days: 1));
            
            final todayData = filteredData.where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month && t.createdAt.day == now.day).toList();
            final yesterdayData = filteredData.where((t) => t.createdAt.year == yesterday.year && t.createdAt.month == yesterday.month && t.createdAt.day == yesterday.day).toList();
            
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
            
            final weekData = filteredData.where((t) {
              final tDate = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
              return (tDate.isAtSameMomentAs(startOfWeekDate) || tDate.isAfter(startOfWeekDate)) &&
                     !todayData.contains(t) && !yesterdayData.contains(t);
            }).toList();
            
            final monthData = filteredData.where((t) {
              return t.createdAt.year == now.year && t.createdAt.month == now.month &&
                     !todayData.contains(t) && !yesterdayData.contains(t) && !weekData.contains(t);
            }).toList();

            final olderData = filteredData.where((t) {
              return !todayData.contains(t) && !yesterdayData.contains(t) && !weekData.contains(t) && !monthData.contains(t);
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Expenses', style: TextStyle(color: Colors.black.withValues(alpha: 0.8), fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Rp ${NumberFormat("#,###", "id_ID").format(filteredData.fold(0.0, (sum, item) => sum + item.amount))}', style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSummarySection(todayTotal, yesterdayTotal, weeklyTotal, monthlyTotal, lastMonthTotal),
                  const SizedBox(height: 32),

                  // Search Bar
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat[0].toUpperCase() + cat.substring(1)),
                            selected: isSelected,
                            onSelected: (selected) => setState(() => _selectedCategory = cat),
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.darkText, fontSize: 12),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Small Charts Section
                  Row(
                    children: [
                      Expanded(child: _buildSmallPieChart(data)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSmallBarChart(data)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sectioned List
                  _buildSection('TODAY', todayData, showEmpty: true),
                  const SizedBox(height: 24),
                  _buildSection('YESTERDAY', yesterdayData, showEmpty: true),
                  const SizedBox(height: 24),
                  _buildSection('THIS WEEK', weekData, showEmpty: true),
                  const SizedBox(height: 24),
                  _buildSection('THIS MONTH', monthData, showEmpty: true),
                  const SizedBox(height: 24),
                  _buildSection('OLDER', olderData, showEmpty: true),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildSmallPieChart(List<TransactionModel> data) {
    final catMap = _processCategoryData(data);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text('By Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 20,
                sections: catMap.entries.map((e) {
                  return PieChartSectionData(
                    color: _getCategoryColor(e.key),
                    value: e.value,
                    title: '',
                    radius: 15,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<TransactionModel> items, {bool showEmpty = false}) {
    if (items.isEmpty && !showEmpty) return const SizedBox.shrink();
    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
            Text('Total -Rp ${NumberFormat("#,###", "id_ID").format(total)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey)))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 32),
            itemBuilder: (context, index) => _buildTransactionItem(items[index]),
          ),
      ],
    );
  }

  Widget _buildSmallBarChart(List<TransactionModel> data) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text('Weekly Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 16),
          const Expanded(child: Center(child: Icon(Icons.show_chart, color: AppColors.primary, size: 40))),
          Text('Activity: High', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => TransactionDetailSheet(transaction: t),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('-Rp ${NumberFormat("#,###", "id_ID").format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM, d yyyy').format(t.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
      ),
    );
  }

  Map<String, double> _processCategoryData(List<TransactionModel> transactions) {
    Map<String, double> data = {};
    for (var t in transactions) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }
    return data;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Colors.orange;
      case 'transportasi': return Colors.blue;
      case 'belanja': return Colors.purple;
      case 'tagihan': return Colors.red;
      case 'kesehatan': return Colors.green;
      default: return Colors.grey;
    }
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

  Widget _buildSummarySection(double today, double yesterday, double weekly, double monthly, double lastMonth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
        const SizedBox(height: 16),
        _buildSummaryRow('Today', today, isHighlight: true),
        _buildSummaryRow('Yesterday', yesterday),
        _buildSummaryRow('This Week', weekly),
        _buildSummaryRow('This Month', monthly),
        _buildSummaryRow('Last Month', lastMonth),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isHighlight ? AppColors.darkText : Colors.grey.shade600, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
          Text('-Rp ${NumberFormat("#,###", "id_ID").format(amount)}', style: TextStyle(color: isHighlight ? Colors.redAccent : AppColors.darkText, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
