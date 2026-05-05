import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction_model.dart';

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
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final todayTotal = ref.watch(todayTotalProvider).value ?? 0.0;
    final yesterdayTotal = ref.watch(yesterdayTotalProvider).value ?? 0.0;
    final weeklyTotal = ref.watch(weeklyTotalProvider).value ?? 0.0;
    final monthlyTotal = ref.watch(monthlyTotalProvider).value ?? 0.0;
    final lastMonthTotal = ref.watch(lastMonthTotalProvider).value ?? 0.0;

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
            if (data.isEmpty) {
              return const Center(child: Text('No transactions yet.'));
            }

            // Filtering logic
            final filteredData = data.where((t) {
              final matchesSearch = t.merchantName.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesCategory = _selectedCategory == 'All' || t.category.toLowerCase() == _selectedCategory.toLowerCase();
              return matchesSearch && matchesCategory;
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
                        Text('Total Expenses', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Rp ${NumberFormat("#,###", "id_ID").format(filteredData.fold(0.0, (sum, item) => sum + item.amount))}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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

                  // Filtered List
                  Text('TRANSACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  if (filteredData.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No results found.')))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredData.length,
                      separatorBuilder: (context, index) => const Divider(height: 32, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) => _buildTransactionItem(filteredData[index]),
                    ),
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
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getCategoryIcon(t.category), color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(DateFormat('MMM, d yyyy').format(t.date), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
        Text('-Rp ${NumberFormat("#,###", "id_ID").format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
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
