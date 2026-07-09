// lib/screens/transactions/widgets/transaction_filters.dart
import 'package:flutter/material.dart';

class TransactionFilters extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const TransactionFilters({
    Key? key,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  State<TransactionFilters> createState() => _TransactionFiltersState();
}

class _TransactionFiltersState extends State<TransactionFilters> {
  String? _selectedCategory;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Utilities',
    'Rent',
    'Healthcare',
    'Education',
    'Salary',
    'Investment',
    'Gift',
    'Travel',
    'Insurance',
    'Other',
  ];

  final List<String> _types = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[850] : Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedType = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  widget.onClear();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            hint: const Text('Category'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category == 'All' ? null : category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // Type dropdown
          DropdownButtonFormField<String>(
            value: _selectedType,
            hint: const Text('Type'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _types.map((type) {
              return DropdownMenuItem(
                value: type == 'All' ? null : type.toLowerCase(),
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // Date range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Start Date',
                          style: TextStyle(
                            color: _startDate != null ? null : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'End Date',
                          style: TextStyle(
                            color: _endDate != null ? null : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply({
                  'category': _selectedCategory,
                  'type': _selectedType,
                  'startDate': _startDate,
                  'endDate': _endDate,
                });
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
