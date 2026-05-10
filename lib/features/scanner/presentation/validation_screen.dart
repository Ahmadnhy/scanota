import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import 'scanner_provider.dart';
import '../../../core/utils/category_utils.dart';
import '../../transactions/data/transaction_repository.dart';

class ValidationScreen extends ConsumerStatefulWidget {
  const ValidationScreen({super.key});

  @override
  ConsumerState<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends ConsumerState<ValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  String _selectedCategory = 'lainnya';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final receiptData = ref.read(scannedReceiptProvider);
    _dateController = TextEditingController(text: receiptData?.date ?? '');
    _merchantController = TextEditingController(text: receiptData?.merchantName ?? '');
    _amountController = TextEditingController(text: receiptData?.totalAmount.toString() ?? '');
    
    final dbCategories = CategoryUtils.getDbCategories();
    if (receiptData != null && receiptData.category.isNotEmpty) {
      String cat = receiptData.category.toLowerCase();
      if (!dbCategories.contains(cat)) {
        _selectedCategory = 'lainnya';
      } else {
        _selectedCategory = cat;
      }
    } else {
      _selectedCategory = 'lainnya';
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveToDatabase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final receiptData = ref.read(scannedReceiptProvider);
      if (receiptData == null) throw Exception('Data struk hilang!');

      final repo = ref.read(transactionRepoProvider);
      final bytes = receiptData.imageBytes;

      String? extension;
      if (bytes != null) {
        final path = receiptData.imagePath;
        final lastDot = path.lastIndexOf('.');
        if (lastDot != -1 && lastDot < path.length - 1) {
          extension = path.substring(lastDot + 1).split('?').first.split('/').first;
        }
        if (extension == null || extension.isEmpty || extension.length > 5) {
          extension = 'jpg';
        }
      }

      await repo.insertTransaction(
        date: _dateController.text,
        merchantName: _merchantController.text,
        amount: double.parse(
          _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
        ),
        category: _selectedCategory,
        imageBytes: bytes,
        imageExtension: extension,
      );

      ref.read(scannedReceiptProvider.notifier).state = null;
      ref.invalidate(transactionsProvider);

      if (mounted) {
        AppNotification.show(context, 'Transaction saved successfully!');
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptData = ref.watch(scannedReceiptProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Verify Data', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (receiptData?.imagePath != null) ...[
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 320),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: receiptData?.imageBytes != null
                                ? Image.memory(receiptData!.imageBytes!, fit: BoxFit.contain)
                                : Image.network(receiptData!.imagePath, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    _buildCleanContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Merchant Name'),
                          TextFormField(
                            controller: _merchantController,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: _inputDecoration(Icons.store_rounded, 'e.g. Starbucks'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Date'),
                          TextFormField(
                            controller: _dateController,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: _inputDecoration(Icons.calendar_today_rounded, 'YYYY-MM-DD'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Total Amount'),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            decoration: _inputDecoration(
                              Icons.payments_rounded,
                              '0.00',
                            ).copyWith(
                              prefixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.payments_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Rp ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.darkText,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldLabel('Category'),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 14),
                            decoration: _inputDecoration(Icons.category_rounded, ''),
                            items: CategoryUtils.getDbCategories().map((c) {
                              return DropdownMenuItem(value: c, child: Text(CategoryUtils.getUiName(c)));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 40,
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
                                            color: Colors.redAccent.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.redAccent,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Discard Data?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Are you sure you want to discard this scanned data? All progress will be lost.',
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
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
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
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.pop();
                                                },
                                                child: const Text(
                                                  'Discard',
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
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.redAccent),
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveToDatabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Save Data', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCleanContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }
}
