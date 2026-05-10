import 'package:flutter/material.dart';
import '../../../../core/utils/category_utils.dart';
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
  final List<String> _categories = ['All', ...CategoryUtils.getDbCategories()];
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0, // Hide the standard app bar title
        ),
        body: transactionsAsync.when(
          data: (data) {
            // Process data once per build
            // Process data: Move processing logic to avoid redundant work
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final yesterdayStart = todayStart.subtract(const Duration(days: 1));
            final weekStart = todayStart.subtract(
              Duration(days: now.weekday - 1),
            );

            // Filtering and grouping in one pass
            final List<TransactionModel> todayData = [];
            final List<TransactionModel> yesterdayData = [];
            final List<TransactionModel> weekData = [];
            final List<TransactionModel> monthData = [];
            final List<TransactionModel> olderData = [];
            final List<TransactionModel> filteredData = [];
            double totalExpenses = 0;

            for (final t in data) {
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  t.merchantName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
              final matchesCategory =
                  _selectedCategory == 'All' ||
                  t.category.toLowerCase() == _selectedCategory.toLowerCase();

              if (matchesSearch && matchesCategory) {
                filteredData.add(t);
                totalExpenses += t.amount;
                final tDate = DateTime(
                  t.createdAt.year,
                  t.createdAt.month,
                  t.createdAt.day,
                );

                if (tDate.isAtSameMomentAs(todayStart)) {
                  todayData.add(t);
                } else if (tDate.isAtSameMomentAs(yesterdayStart)) {
                  yesterdayData.add(t);
                } else if (tDate.isAfter(
                  weekStart.subtract(const Duration(seconds: 1)),
                )) {
                  weekData.add(t);
                } else if (t.createdAt.year == now.year &&
                    t.createdAt.month == now.month) {
                  monthData.add(t);
                } else {
                  olderData.add(t);
                }
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Analytics Report',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Expenses Card
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
                              Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp ${NumberFormat("#,###", "id_ID").format(totalExpenses)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Optimized Summary Watchers
                        const _SummarySection(),
                        const SizedBox(height: 32),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged:
                                (value) => setState(() => _searchQuery = value),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search merchant or category...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
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
                                  label: Text(
                                    cat == 'All'
                                        ? 'All'
                                        : CategoryUtils.getUiName(cat),
                                  ),
                                  selected: isSelected,
                                  onSelected:
                                      (selected) => setState(
                                        () => _selectedCategory = cat,
                                      ),
                                  selectedColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : AppColors.darkText,
                                    fontSize: 12,
                                  ),
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Charts Section
                        _buildInteractiveCard(
                          title: 'Category Distribution',
                          child: _buildPieChartSample2(filteredData),
                          onTap:
                              () => _showChartDetail(
                                context,
                                'Category Distribution',
                                _processCategoryData(filteredData),
                                isPie: true,
                              ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Transaction Sections
                ..._buildSliverSection('TODAY', todayData, showEmpty: true),
                ..._buildSliverSection('YESTERDAY', yesterdayData),
                ..._buildSliverSection('THIS WEEK', weekData),
                ..._buildSliverSection('THIS MONTH', monthData),
                ..._buildSliverSection('OLDER', olderData),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildInteractiveCard({
    required String title,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280, // Fixed height to prevent unbounded constraint error
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.darkText,
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: RepaintBoundary(child: child)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSample2(List<TransactionModel> data) {
    final catMap = _processCategoryData(data);
    if (catMap.isEmpty) {
      return const Center(
        child: Icon(Icons.pie_chart_outline, color: Colors.grey),
      );
    }

    final sortedEntries =
        catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(4).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (!mounted) return;
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections:
                  topEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    final isTouched = index == _touchedPieIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    return PieChartSectionData(
                      color: CategoryUtils.getColor(e.key),
                      value: e.value,
                      title:
                          isTouched
                              ? 'Rp ${NumberFormat.compact().format(e.value)}'
                              : '${(e.value / catMap.values.fold(0.0, (s, v) => s + v) * 100).toStringAsFixed(0)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              topEntries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: CategoryUtils.getColor(e.key),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CategoryUtils.getUiName(e.key),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showChartDetail(
    BuildContext context,
    String title,
    Map<dynamic, double> data, {
    bool isPie = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final key = data.keys.elementAt(index);
                      final val = data.values.elementAt(index);
                      String label = key.toString();
                      if (title.contains('Category')) {
                        label = CategoryUtils.getUiName(label);
                      }
                      if (title.contains('Weekly')) {
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        label = days[key % 7];
                      }
                      return ListTile(
                        leading:
                            isPie
                                ? Icon(
                                  CategoryUtils.getIcon(key.toString()),
                                  color: CategoryUtils.getColor(key.toString()),
                                )
                                : const Icon(
                                  Icons.analytics_outlined,
                                  color: AppColors.primary,
                                ),
                        title: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          'Rp ${NumberFormat("#,###", "id_ID").format(val)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  List<Widget> _buildSliverSection(
    String title,
    List<TransactionModel> items, {
    bool showEmpty = false,
  }) {
    if (items.isEmpty && !showEmpty) return [];

    final total = items.fold(0.0, (sum, item) => sum + item.amount);

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Total ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: '-Rp ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    TextSpan(
                      text: NumberFormat("#,###", "id_ID").format(total),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (items.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No transactions found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  _buildTransactionItem(items[index]),
                  if (!isLast)
                    const Divider(color: Color(0xFFF1F5F9), height: 32),
                  if (isLast) const SizedBox(height: 16),
                ],
              );
            }, childCount: items.length),
          ),
        ),
    ];
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
                        style: const TextStyle(fontSize: 16),
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
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Map<String, double> _processCategoryData(
    List<TransactionModel> transactions,
  ) {
    Map<String, double> data = {};
    for (var t in transactions) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }
    return data;
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayTotalProvider);
    final yesterday = ref.watch(yesterdayTotalProvider);
    final weekly = ref.watch(weeklyTotalProvider);
    final monthly = ref.watch(monthlyTotalProvider);
    final lastMonth = ref.watch(lastMonthTotalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUMMARY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryRow('Today', today, isHighlight: true),
        _buildSummaryRow('Yesterday', yesterday),
        _buildSummaryRow('This Week', weekly),
        _buildSummaryRow('This Month', monthly),
        _buildSummaryRow('Last Month', lastMonth),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppColors.darkText : Colors.grey.shade600,
              fontWeight: FontWeight.bold, // Always bold for better visibility
            ),
          ),
          Text(
            '-Rp ${NumberFormat("#,###", "id_ID").format(amount)}',
            style: TextStyle(
              color: isHighlight ? Colors.redAccent : AppColors.darkText,
              fontWeight: FontWeight.bold, // Always bold for better visibility
            ),
          ),
        ],
      ),
    );
  }
}
