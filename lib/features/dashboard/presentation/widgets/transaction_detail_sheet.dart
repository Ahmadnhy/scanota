import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction_model.dart';

class TransactionDetailSheet extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  const TransactionDetailSheet({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends ConsumerState<TransactionDetailSheet> {
  bool _isEditing = false;
  late TextEditingController _dateController;
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late String _selectedCategory;
  final List<String> _categories = ['makanan', 'transportasi', 'belanja', 'tagihan', 'kesehatan', 'hiburan', 'lainnya'];

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(widget.transaction.date));
    _merchantController = TextEditingController(text: widget.transaction.merchantName);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _selectedCategory = widget.transaction.category.toLowerCase();
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    try {
      await ref.read(transactionRepoProvider).updateTransaction(
        id: widget.transaction.id,
        date: _dateController.text,
        merchantName: _merchantController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
      );
      ref.invalidate(transactionsProvider);
      if (mounted) {
        Navigator.pop(context);
        AppNotification.show(context, 'Transaction updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Failed to update: $e', isError: true);
      }
    }
  }

  void _deleteTransaction() {
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 24),
              const Text('Delete Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
              const SizedBox(height: 8),
              Text('Are you sure you want to delete this transaction?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        await ref.read(transactionRepoProvider).deleteTransaction(widget.transaction.id);
                        ref.invalidate(transactionsProvider);
                        if (context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          AppNotification.show(context, 'Transaction deleted');
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isEditing ? 'Edit Transaction' : 'Transaction Detail', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
              if (!_isEditing)
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.primary), onPressed: () => setState(() => _isEditing = true)),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: _deleteTransaction),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing && widget.transaction.imageUrl != null) ...[
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.transaction.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_isEditing) ...[
                    _buildFieldLabel('Date'),
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(hintText: 'YYYY-MM-DD', prefixIcon: Icon(Icons.calendar_today_rounded, size: 20)),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Merchant Name'),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(hintText: 'e.g. Starbucks', prefixIcon: Icon(Icons.store_rounded, size: 20)),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Total Amount'),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.payments_rounded, size: 20), prefixText: 'Rp '),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Category'),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.category_rounded, size: 20)),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ] else ...[
                    _buildDetailRow('Merchant', widget.transaction.merchantName, Icons.store_rounded),
                    _buildDetailRow('Date', DateFormat('EEEE, d MMMM yyyy').format(widget.transaction.date), Icons.calendar_today_rounded),
                    _buildDetailRow('Category', widget.transaction.category.toUpperCase(), Icons.category_rounded),
                    _buildDetailRow('Amount', 'Rp ${NumberFormat("#,###", "id_ID").format(widget.transaction.amount)}', Icons.payments_rounded, isAmount: true),
                    const SizedBox(height: 24),
                    _buildDetailRow('Inputted On', DateFormat('MMM d, yyyy HH:mm').format(widget.transaction.createdAt), Icons.access_time_rounded),
                  ],
                ],
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isEditing = false;
                      _dateController.text = DateFormat('yyyy-MM-dd').format(widget.transaction.date);
                      _merchantController.text = widget.transaction.merchantName;
                      _amountController.text = widget.transaction.amount.toString();
                      _selectedCategory = widget.transaction.category.toLowerCase();
                    }),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _saveChanges,
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText.withValues(alpha: 0.7), fontSize: 13)),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isAmount = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: isAmount ? 20 : 16, fontWeight: isAmount ? FontWeight.w800 : FontWeight.bold, color: AppColors.darkText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
