// lib/screens/reports/widgets/report_filter_widget.dart
import 'package:flutter/material.dart';

class ReportFilterWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const ReportFilterWidget({
    Key? key,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  State<ReportFilterWidget> createState() => _ReportFilterWidgetState();
}

class _ReportFilterWidgetState extends State<ReportFilterWidget> {
  String? _selectedCategory;
  String? _selectedType;
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[850] : Colors.grey[50],
      child: Column(
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
                    _selectedDateRange = null;
                    _minAmount = null;
                    _maxAmount = null;
                  });
                  widget.onClear();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Income', 'income'),
              _buildFilterChip('Expense', 'expense'),
              _buildFilterChip('Transfer', 'transfer'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateRangePicker(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Min Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _minAmount = double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Max Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxAmount = double.tryParse(value);
                  },
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
                  'startDate': _selectedDateRange?.start,
                  'endDate': _selectedDateRange?.end,
                  'minAmount': _minAmount,
                  'maxAmount': _maxAmount,
                });
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? value : null;
        });
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildDateRangePicker() {
    final textStyle = TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : Colors.black87,
    );

    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _selectedDateRange,
        );
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}'
                    : 'Select Date Range',
                style: textStyle,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
