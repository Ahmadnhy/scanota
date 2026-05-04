import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFB4D3D9);
  static const Color darkText = Color(0xFF1E293B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color secondaryText = Color(0xFF64748B);
  static const Color accent = Color(0xFF94A3B8);
  
  // Gradient untuk area header
  static LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary.withValues(alpha: 0.2),
      Colors.white,
    ],
  );
}
