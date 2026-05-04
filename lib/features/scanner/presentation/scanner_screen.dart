import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import 'scanner_provider.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerControllerProvider);

    ref.listen<AsyncValue<void>>(scannerControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (ref.read(scannedReceiptProvider) != null) {
            context.push('/validation');
          }
        },
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membaca struk: $err'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan New Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.primary),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Ready to Scan?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkText, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take a clear photo of your receipt or upload from your gallery. Our AI will handle the rest.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 60),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            onTap: () => ref.read(scannerControllerProvider.notifier).processReceipt(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildModernActionButton(
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery',
                            onTap: () => ref.read(scannerControllerProvider.notifier).processReceipt(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (scannerState.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 24),
                          Text(
                            'AI is Analyzing...',
                            style: TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Extracting data from receipt',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
