import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_notification.dart';
import '../data/transaction_repository.dart';
import '../../scanner/presentation/scanner_provider.dart';

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
  bool _isAnalyzingImage = false;
  XFile? _selectedImage;

  final List<String> _categories = [
    'makanan',
    'transportasi',
    'belanja',
    'tagihan',
    'kesehatan',
    'hiburan',
    'lainnya',
  ];

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

  Future<void> _generateWithAI() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzingImage = true;
    });

    try {
      final geminiRepo = ref.read(geminiRepoProvider);
      final bytes = await _selectedImage!.readAsBytes();
      final jsonString = await geminiRepo.analyzeReceipt(bytes);
      final cleanedStr =
          jsonString
              .replaceAll(RegExp(r'```(?:json)?\n?'), '')
              .replaceAll('```', '')
              .trim();
      final Map<String, dynamic> jsonData = jsonDecode(cleanedStr);

      setState(() {
        if (jsonData['tanggal'] != null) {
          _dateController.text = jsonData['tanggal'];
        }
        if (jsonData['nama_merchant'] != null) {
          _merchantController.text = jsonData['nama_merchant'];
        }
        if (jsonData['total_pengeluaran'] != null) {
          _amountController.text = jsonData['total_pengeluaran'].toString();
        }
        if (jsonData['kategori'] != null) {
          String cat = jsonData['kategori'].toString().toLowerCase();
          if (!_categories.contains(cat)) {
            _categories.add(cat);
          }
          _selectedCategory = cat;
        }
      });
      if (mounted) {
        AppNotification.show(context, 'Receipt analyzed successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          'Failed to scan receipt: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzingImage = false);
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
        // Safely extract extension — on web, XFile.path can be a blob: URL
        final path = _selectedImage!.path;
        final lastDot = path.lastIndexOf('.');
        if (lastDot != -1 && lastDot < path.length - 1) {
          extension =
              path.substring(lastDot + 1).split('?').first.split('/').first;
        }
        if (extension == null || extension.isEmpty || extension.length > 5) {
          extension = 'jpg'; // safe fallback
        }
      }

      await repo.insertTransaction(
        date: _dateController.text,
        merchantName: _merchantController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        imageBytes: bytes,
        imageExtension: extension,
      );

      // Force refresh the transactions stream so dashboard updates immediately
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manual Entry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child:
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
                          // Image Picker Box
                          GestureDetector(
                            onTap: _pickImage,
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    width: double.infinity,
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
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (_selectedImage != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: FutureBuilder<Uint8List>(
                                              future: _selectedImage!.readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.contain,
                                                  );
                                                }
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                            ),
                                          )
                                        else
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 48,
                                                color: AppColors.primary.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Upload Receipt (Optional)',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (_isAnalyzingImage)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                              child: Container(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.white,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const SizedBox(
                                                          width: 32,
                                                          height: 32,
                                                          child: CircularProgressIndicator(
                                                            color: AppColors.primary,
                                                            strokeWidth: 3,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      const Text(
                                                        'AI Processing...',
                                                        style: TextStyle(
                                                          color: AppColors.darkText,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _generateWithAI,
                                icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Generate With AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          _buildSectionTitle('Transaction Details'),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Date'),
                          TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              hintText: 'YYYY-MM-DD',
                              prefixIcon: Icon(
                                Icons.calendar_today_rounded,
                                size: 20,
                              ),
                            ),
                            validator:
                                (v) => v!.isEmpty ? 'Date is required' : null,
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel('Merchant Name'),
                          TextFormField(
                            controller: _merchantController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Starbucks, Indomaret',
                              prefixIcon: Icon(Icons.store_rounded, size: 20),
                            ),
                            validator:
                                (v) =>
                                    v!.isEmpty
                                        ? 'Merchant name is required'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel('Total Amount'),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              prefixIcon: Icon(
                                Icons.payments_rounded,
                                size: 20,
                              ),
                              prefixText: 'Rp ',
                            ),
                            validator:
                                (v) => v!.isEmpty ? 'Amount is required' : null,
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel('Category'),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.category_rounded,
                                size: 20,
                              ),
                            ),
                            items:
                                _categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c.toUpperCase(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (v) => setState(() => _selectedCategory = v!),
                          ),

                          const SizedBox(height: 48),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.black, // Dark active color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _saveTransaction,
                              child: const Text(
                                'Save Transaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => context.pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1,
                                ),
                                elevation: 0,
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
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkText.withValues(alpha: 0.7),
          fontSize: 13,
        ),
      ),
    );
  }
}
