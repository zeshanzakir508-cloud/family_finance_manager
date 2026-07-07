// lib/screens/transactions/split_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart'; // ✅ ADDED: Missing import
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/category_picker.dart';

class SplitTransactionScreen extends StatefulWidget {
  final double totalAmount;
  final String? parentTransactionId;

  const SplitTransactionScreen({
    Key? key,
    required this.totalAmount,
    this.parentTransactionId,
  }) : super(key: key);

  @override
  State<SplitTransactionScreen> createState() => _SplitTransactionScreenState();
}

class _SplitTransactionScreenState extends State<SplitTransactionScreen> {
  final List<SplitItem> _splits = [];
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  double _remainingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _remainingAmount = widget.totalAmount;
    // Add initial split
    _addSplit();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addSplit() {
    setState(() {
      _splits.add(SplitItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: 0.0,
        category: null,
        description: '',
      ));
      _updateRemaining();
    });
  }

  void _removeSplit(String id) {
    if (_splits.length <= 1) {
      CustomSnackBar.show(
        context,
        'At least one split is required',
        isError: true,
      );
      return;
    }
    setState(() {
      _splits.removeWhere((s) => s.id == id);
      _updateRemaining();
    });
  }

  void _updateSplitAmount(String id, double amount) {
    setState(() {
      final index = _splits.indexWhere((s) => s.id == id);
      if (index != -1) {
        _splits[index] = _splits[index].copyWith(amount: amount);
        _updateRemaining();
      }
    });
  }

  void _updateSplitCategory(String id, String? categoryId) {
    setState(() {
      final index = _splits.indexWhere((s) => s.id == id);
      if (index != -1) {
        _splits[index] = _splits[index].copyWith(category: categoryId);
      }
    });
  }

  void _updateSplitDescription(String id, String description) {
    setState(() {
      final index = _splits.indexWhere((s) => s.id == id);
      if (index != -1) {
        _splits[index] = _splits[index].copyWith(description: description);
      }
    });
  }

  void _updateRemaining() {
    final total = _splits.fold(0.0, (sum, s) => sum + s.amount);
    _remainingAmount = widget.totalAmount - total;
  }

  void _autoSplitEqually() {
    if (_splits.isEmpty) return;
    final equalAmount = widget.totalAmount / _splits.length;
    setState(() {
      for (var split in _splits) {
        split.amount = equalAmount;
      }
      _updateRemaining();
    });
  }

  void _autoSplitByPercentage() {
    if (_splits.isEmpty) return;
    // Distribute remaining amount evenly
    _autoSplitEqually();
  }

  Future<void> _saveSplits() async {
    // Validate splits
    for (var split in _splits) {
      if (split.amount <= 0) {
        CustomSnackBar.show(
          context,
          'Each split must have a positive amount',
          isError: true,
        );
        return;
      }
      if (split.category == null) {
        CustomSnackBar.show(
          context,
          'Please select a category for each split',
          isError: true,
        );
        return;
      }
    }

    if (_remainingAmount.abs() > 0.01) {
      CustomSnackBar.show(
        context,
        'Total amount (${widget.totalAmount}) does not match splits (${widget.totalAmount - _remainingAmount})',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Save split transactions
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      CustomSnackBar.show(
        context,
        'Split transaction saved successfully!',
      );
      Navigator.pop(context, true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseCategories = categoryProvider.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.equalizer),
            onPressed: _autoSplitEqually,
            tooltip: 'Split equally',
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveSplits,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total amount summary
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${currencyProvider.currentCurrency} ${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: _remainingAmount.abs() > 0.01
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    Text(
                      '${currencyProvider.currentCurrency} ${_remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _remainingAmount.abs() > 0.01
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (widget.totalAmount - _remainingAmount) / widget.totalAmount,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  color: _remainingAmount.abs() > 0.01 ? Colors.orange : Colors.green,
                  minHeight: 6,
                ),
              ],
            ),
          ),
          // Split list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _splits.length,
              itemBuilder: (context, index) {
                final split = _splits[index];
                return _buildSplitItem(
                  index,
                  split,
                  expenseCategories,
                  currencyProvider.currentCurrency,
                );
              },
            ),
          ),
          // Add split button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addSplit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Split'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _autoSplitEqually,
                    icon: const Icon(Icons.equalizer),
                    label: const Text('Split Equally'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitItem(
    int index,
    SplitItem split,
    List<CategoryModel> categories,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Split ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeSplit(split.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: split.amount > 0 ? split.amount.toString() : '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '$currency ',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    _updateSplitAmount(
                      split.id,
                      double.tryParse(value) ?? 0.0,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: CategoryPicker(
                  categories: categories,
                  selectedId: split.category,
                  onChanged: (id) => _updateSplitCategory(split.id, id),
                  label: 'Category',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: split.description,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) => _updateSplitDescription(split.id, value),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SPLIT ITEM MODEL
// ============================================================

class SplitItem {
  final String id;
  double amount;
  String? category;
  String description;

  SplitItem({
    required this.id,
    required this.amount,
    this.category,
    this.description = '',
  });

  SplitItem copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
  }) {
    return SplitItem(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}
