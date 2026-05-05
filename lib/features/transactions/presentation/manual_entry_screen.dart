import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../data/transaction_repository.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'lainnya';
  bool _isLoading = false;
  XFile? _selectedImage;

  final List<String> _categories = ['makanan', 'transportasi', 'belanja', 'tagihan', 'kesehatan', 'hiburan', 'lainnya'];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transactionRepoProvider);
      
      Uint8List? bytes;
      String? extension;
      if (_selectedImage != null) {
        bytes = await _selectedImage!.readAsBytes();
        extension = _selectedImage!.path.split('.').last;
      }

      await repo.insertTransaction(
        date: _dateController.text,
        merchantName: _merchantController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        imageBytes: bytes,
        imageExtension: extension,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction saved successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
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
                        // Image Picker Box
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(_selectedImage!.path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.file(File(_selectedImage!.path), fit: BoxFit.cover)),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                                      const SizedBox(height: 16),
                                      Text('Upload Receipt (Optional)', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Dark active color
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _saveTransaction,
                            child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText));
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText.withValues(alpha: 0.7), fontSize: 13)),
    );
  }
}
