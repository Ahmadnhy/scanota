import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // 1. Jalankan timer 4 detik
    final timer = Future.delayed(const Duration(seconds: 4));

    // 2. Tunggu sampai data Auth siap (bisa lebih cepat atau lebih lambat dari 2 detik)
    try {
      final authState = await ref.read(authStateProvider.future);

      // 3. Pastikan timer 4 detik sudah selesai sebelum pindah halaman
      await timer;

      if (!mounted) return;

      // 4. Navigasi berdasarkan session
      if (authState.session != null) {
        context.go('/dashboard');
      } else {
        context.go('/welcome');
      }
    } catch (e) {
      // Jika terjadi error auth, pastikan tetap pindah ke welcome setelah 4 detik
      await timer;
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Icon(
                Icons.stars_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Expense Snap',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.darkText, letterSpacing: -1),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
