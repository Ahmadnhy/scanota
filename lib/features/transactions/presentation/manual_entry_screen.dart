import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import '../../scanner/presentation/scanner_provider.dart';
import '../../../core/utils/category_utils.dart';
import '../data/transaction_repository.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'lainnya';
  Uint8List? _selectedImage;
  String? _imagePath;
  bool _isAnalyzingImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ').first;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _imagePath = image.path;
      });
    }
  }

  Future<void> _generateWithAI() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalyzingImage = true);

    try {
      final scanner = ref.read(scannerControllerProvider.notifier);
      final result = await scanner.analyzeReceiptBytes(
        _selectedImage!,
        _imagePath!,
      );

      setState(() {
        _merchantController.text = result.merchantName;
        _dateController.text = result.date;
        _amountController.text = result.totalAmount.toString();

        final dbCategories = CategoryUtils.getDbCategories();
        String cat = result.category.toLowerCase();
        _selectedCategory = dbCategories.contains(cat) ? cat : 'lainnya';
      });

      if (mounted)
        AppNotification.show(context, 'Data extracted successfully!');
    } catch (e) {
      if (mounted)
        AppNotification.show(context, 'AI failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAnalyzingImage = false);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transactionRepoProvider);

      String? extension;
      if (_selectedImage != null && _imagePath != null) {
        final lastDot = _imagePath!.lastIndexOf('.');
        if (lastDot != -1 && lastDot < _imagePath!.length - 1) {
          extension =
              _imagePath!
                  .substring(lastDot + 1)
                  .split('?')
                  .first
                  .split('/')
                  .first;
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
        imageBytes: _selectedImage,
        imageExtension: extension,
      );

      ref.invalidate(transactionsProvider);
      if (mounted) {
        AppNotification.show(context, 'Transaction saved!');
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted)
        AppNotification.show(context, 'Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manual Entry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 320),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child:
                                    _selectedImage != null
                                        ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.memory(
                                              _selectedImage!,
                                              fit: BoxFit.contain,
                                            ),
                                            if (_isAnalyzingImage)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 8,
                                                    sigmaY: 8,
                                                  ),
                                                  child: Container(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const SizedBox(
                                                            width: 60,
                                                            height: 60,
                                                            child: CircularProgressIndicator(
                                                              color:
                                                                  AppColors
                                                                      .primary,
                                                              strokeWidth: 6,
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),
                                                          Text(
                                                            'AI is analyzing your receipt...',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  AppColors
                                                                      .darkText,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                        : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo_rounded,
                                              size: 48,
                                              color: Colors.grey.shade300,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Add Receipt Image (Optional)',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_selectedImage != null && !_isAnalyzingImage) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _generateWithAI,
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text('Fill with AI Analysis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      _buildCleanContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Merchant Name'),
                            TextFormField(
                              controller: _merchantController,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: _inputDecoration(
                                Icons.store_rounded,
                                'e.g. Starbucks',
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildFieldLabel('Date'),
                            TextFormField(
                              controller: _dateController,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: _inputDecoration(
                                Icons.calendar_today_rounded,
                                'YYYY-MM-DD',
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildFieldLabel('Total Amount'),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                                fontSize: 14,
                              ),
                              decoration: _inputDecoration(
                                Icons.category_rounded,
                                '',
                              ),
                              items:
                                  CategoryUtils.getDbCategories().map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(CategoryUtils.getUiName(c)),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => setState(() => _selectedCategory = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Transaction',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => Dialog(
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
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.1),
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
                                            'Discard Entry?',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkText,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Are you sure you want to discard this entry? All unsaved data will be lost.',
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
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
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
                                                    'Keep Editing',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                    padding:
                                                        const EdgeInsets.symmetric(
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Discard',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
