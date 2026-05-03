import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../features/transactions/domain/transaction_model.dart';

class CategoryChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const CategoryChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    Map<String, double> data = {};
    for (var t in transactions) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }

    final List<Color> colors = [Colors.teal, Colors.orange, Colors.red, Colors.blue, Colors.purple, Colors.amber];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: data.entries.map((e) {
          int index = data.keys.toList().indexOf(e.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: e.value,
            title: '',
            radius: 50,
          );
        }).toList(),
      ),
    );
  }
}
