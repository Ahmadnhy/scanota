import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/scanner/presentation/validation_screen.dart';
import '../../features/transactions/presentation/manual_entry_screen.dart';

final navigatorKeyProvider = Provider((ref) => GlobalKey<NavigatorState>());

final routerProvider = Provider<GoRouter>((ref) {
  final navigatorKey = ref.watch(navigatorKeyProvider);
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/scanner', builder: (context, state) => const ScannerScreen()),
      GoRoute(path: '/validation', builder: (context, state) => const ValidationScreen()),
      GoRoute(path: '/manual-entry', builder: (context, state) => const ManualEntryScreen()),
    ],
  );
});
