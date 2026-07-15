// lib/screens/budget/budget_templates_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/budget_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/budget_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/budget_card.dart';

class BudgetTemplatesScreen extends StatefulWidget {
  const BudgetTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<BudgetTemplatesScreen> createState() => _BudgetTemplatesScreenState();
}

class _BudgetTemplatesScreenState extends State<BudgetTemplatesScreen> {
  List<BudgetModel> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AppAuthProvider>(); // ✅ Fixed
      final query = await FirebaseFirestore.instance
          .collection('budget_templates')
          .where('userId', isEqualTo: auth.userId)
          .get();

      _templates = query.docs.map((doc) {
        final data = doc.data();
        return BudgetModel.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading templates: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to load templates: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _applyTemplate(BudgetModel template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Template'),
        content: Text(
          'Create a new budget from "${template.name}" for this month?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final auth = context.read<AppAuthProvider>(); // ✅ Fixed
        final budgetProvider = context.read<BudgetProvider>();
        final now = DateTime.now();

        final newBudget = template.copyWith(
          id: '',
          userId: auth.userId,
          month: now.month,
          year: now.year,
          totalSpent: 0.0,
          totalRemaining: template.totalAllocated,
          createdAt: DateTime.now(),
          updatedAt: null,
          isActive: true,
          categories: template.categories.map((c) => c.copyWith(
            spent: 0.0,
            remaining: c.allocated,
          )).toList(),
        );

        final success = await budgetProvider.createBudget(newBudget);

        if (success && mounted) {
          CustomSnackBar.show(
            context,
            'Budget created from template! 📊',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to apply template: ${e.toString()}',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _deleteTemplate(BudgetModel template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Delete "${template.name}" template?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('budget_templates')
            .doc(template.id)
            .delete();

        setState(() {
          _templates.removeWhere((t) => t.id == template.id);
        });

        if (mounted) {
          CustomSnackBar.show(
            context,
            'Template deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to delete template: ${e.toString()}',
            isError: true,
          );
        }
      }
    }
  }

  // ✅ FIXED: Save current budget as template
  Future<void> _saveTemplate(String name, String description) async {
    try {
      final auth = context.read<AppAuthProvider>(); // ✅ Fixed
      final budgetProvider = context.read<BudgetProvider>();
      final currentBudget = budgetProvider.currentBudget;

      if (currentBudget == null) {
        CustomSnackBar.show(
          context,
          'No current budget to save as template',
          isError: true,
        );
        return;
      }

      final templateData = currentBudget.toJson();
      templateData['name'] = name;
      templateData['description'] = description;
      templateData['userId'] = auth.userId;
      templateData['createdAt'] = FieldValue.serverTimestamp();
      templateData['isTemplate'] = true;
      
      // ✅ FIXED: Use remove() instead of pop()
      templateData.remove('id');
      templateData.remove('createdAt');

      final docRef = await FirebaseFirestore.instance
          .collection('budget_templates')
          .add(templateData);

      final newTemplate = currentBudget.copyWith(
        id: docRef.id,
        name: name,
        description: description,
      );

      setState(() {
        _templates.insert(0, newTemplate);
      });

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Template saved successfully! 📋',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to save template: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showSaveTemplateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.copy,
                  title: 'No Templates',
                  description: 'Save your budget as a template for quick reuse.',
                  buttonText: 'Save Current Budget',
                  onPressed: _showSaveTemplateDialog,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (template.description?.isNotEmpty ?? false)
                                      Text(
                                        template.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'apply') {
                                    _applyTemplate(template);
                                  } else if (value == 'delete') {
                                    _deleteTemplate(template);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'apply',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check, size: 18),
                                        SizedBox(width: 8),
                                        Text('Apply'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${template.categories.length} categories',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${currencyProvider.currentCurrency} ${template.totalAllocated.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            onPressed: () => _applyTemplate(template),
                            text: 'Apply Template',
                            type: ButtonType.outline,
                            size: ButtonSize.small,
                            icon: Icons.check,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showSaveTemplateDialog() {
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                CustomSnackBar.show(
                  context,
                  'Please enter a template name',
                  isError: true,
                );
                return;
              }
              Navigator.pop(context);
              _saveTemplate(
                _nameController.text.trim(),
                _descriptionController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
