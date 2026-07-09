// lib/screens/transactions/widgets/category_picker.dart
import 'package:flutter/material.dart';
import '../../../models/category_model.dart';

class CategoryPicker extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String label;

  const CategoryPicker({
    Key? key,
    required this.categories,
    this.selectedId,
    required this.onChanged,
    this.label = 'Category',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      hint: Text(label),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category.id,
          child: Row(
            children: [
              Icon(
                category.iconData,
                size: 18,
                color: category.colorValue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
