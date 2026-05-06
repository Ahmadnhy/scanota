import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import 'scanner_provider.dart';
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

  final List<String> _categories = [
    'makanan',
    'transportasi',
    'belanja',
    'tagihan',
    'kesehatan',
    'hiburan',
    'lainnya'
  ];

  @override
  void initState() {
    super.initState();
    final receiptData = ref.read(scannedReceiptProvider);
    _dateController = TextEditingController(text: receiptData?.date ?? '');
    _merchantController = TextEditingController(text: receiptData?.merchantName ?? '');
    _amountController = TextEditingController(text: receiptData?.totalAmount.toString() ?? '');
    if (receiptData != null && receiptData.category.isNotEmpty) {
      String cat = receiptData.category.toLowerCase();
      if (!_categories.contains(cat)) {
        _categories.add(cat);
      }
      _selectedCategory = cat;
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

      final bytes = receiptData.imageBytes ?? await XFile(receiptData.imagePath).readAsBytes();
      final extension = receiptData.imagePath.split('.').last.split('?').first;

      await repo.insertTransaction(
        date: _dateController.text,
        merchantName: _merchantController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        imageBytes: bytes,
        imageExtension: extension,
      );

      ref.read(scannedReceiptProvider.notifier).state = null;

      // Force refresh the transactions stream so dashboard updates immediately
      ref.invalidate(transactionsStreamProvider);

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
      appBar: AppBar(
        title: const Text('Verify Data', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Receipt Image Preview Card
                        if (receiptData?.imagePath != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                  child: receiptData?.imageBytes != null
                                      ? Image.memory(
                                          receiptData!.imageBytes!,
                                          height: 250,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          receiptData!.imagePath,
                                          height: 250,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 250,
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                          ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Processed Receipt',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),

                        _buildSectionTitle('Transaction Details'),
                        const SizedBox(height: 16),

                        _buildFieldLabel('Date'),
                        TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                          ),
                          validator: (v) => v!.isEmpty ? 'Date is required' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildFieldLabel('Merchant Name'),
                        TextFormField(
                          controller: _merchantController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Starbucks, Indomaret',
                            prefixIcon: Icon(Icons.store_rounded, size: 20),
                          ),
                          validator: (v) => v!.isEmpty ? 'Merchant name is required' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildFieldLabel('Total Amount'),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.payments_rounded, size: 20),
                            prefixText: 'Rp ',
                          ),
                          validator: (v) => v!.isEmpty ? 'Amount is required' : null,
                        ),
                        const SizedBox(height: 20),

                        _buildFieldLabel('Category'),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category_rounded, size: 20),
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),

                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _saveToDatabase,
                            child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Discard', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText.withValues(alpha: 0.7), fontSize: 13),
      ),
    );
  }
}
