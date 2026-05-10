import 'package:flutter/material.dart';

class CategoryUtils {
  static const Map<String, String> _dbToUi = {
    'makanan': 'Food',
    'transportasi': 'Transport',
    'belanja': 'Shopping',
    'tagihan': 'Bills',
    'kesehatan': 'Health',
    'hiburan': 'Entertainment',
    'lainnya': 'Others',
  };

  static String getUiName(String dbName) {
    final lower = dbName.toLowerCase();
    return _dbToUi[lower] ?? dbName[0].toUpperCase() + dbName.substring(1);
  }

  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
      case 'food':
        return Icons.restaurant_rounded;
      case 'transportasi':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'belanja':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'tagihan':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'kesehatan':
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'hiburan':
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
      case 'food':
        return const Color(0xFFFFB347); // Soft Orange
      case 'transportasi':
      case 'transport':
        return const Color(0xFF77DDFF); // Soft Blue
      case 'belanja':
      case 'shopping':
        return const Color(0xFFB39DDB); // Soft Purple
      case 'tagihan':
      case 'bills':
        return const Color(0xFFFF6961); // Soft Red
      case 'kesehatan':
      case 'health':
        return const Color(0xFF77DD77); // Soft Green
      case 'hiburan':
      case 'entertainment':
        return const Color(0xFFF49AC2); // Soft Pink
      default:
        return const Color(0xFFAEC6CF); // Soft Grey-Blue
    }
  }

  static List<String> getDbCategories() => _dbToUi.keys.toList();
}
