// lib/screens/budget/widgets/category_budget_item.dart
import 'package:flutter/material.dart';
import '../../../models/budget_model.dart';

class CategoryBudgetItemWidget extends StatelessWidget {
  final CategoryBudgetItem item;
  final String currency;
  final ValueChanged<double> onChanged;

  const CategoryBudgetItemWidget({
    Key? key,
    required this.item,
    required this.currency,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item.categoryName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: item.allocated > 0 ? item.allocated.toString() : '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '$currency ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: (value) {
                onChanged(double.tryParse(value) ?? 0.0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
