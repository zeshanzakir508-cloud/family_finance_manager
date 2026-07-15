// lib/screens/goals/add_goal_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/category_provider.dart';
import '../../models/goal_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'widgets/goal_progress_circle.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({Key? key}) : super(key: key);

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCategory;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'savings', 'label': 'Savings', 'icon': Icons.savings},
    {'id': 'debt', 'label': 'Debt Repayment', 'icon': Icons.credit_card},
    {'id': 'investment', 'label': 'Investment', 'icon': Icons.trending_up},
    {'id': 'vacation', 'label': 'Vacation', 'icon': Icons.beach_access},
    {'id': 'education', 'label': 'Education', 'icon': Icons.school},
    {'id': 'emergency', 'label': 'Emergency Fund', 'icon': Icons.security},
    {'id': 'vehicle', 'label': 'Vehicle', 'icon': Icons.directions_car},
    {'id': 'home', 'label': 'Home', 'icon': Icons.home},
    {'id': 'other', 'label': 'Other', 'icon': Icons.flag},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      CustomSnackBar.show(
        context,
        'Please select a category',
        isError: true,
      );
      return;
    }
    if (_selectedDeadline == null) {
      CustomSnackBar.show(
        context,
        'Please select a deadline',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: AuthProvider → AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      final goalProvider = context.read<GoalProvider>();
      
      final category = _categories.firstWhere(
        (c) => c['id'] == _selectedCategory,
      );

      final goal = GoalModel(
        id: '',
        userId: auth.userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: double.parse(_targetController.text.trim()),
        currentAmount: 0.0,
        deadline: _selectedDeadline,
        category: category['label'],
        icon: category['icon'].toString(),
        color: _getCategoryColor(_selectedCategory!),
        createdAt: DateTime.now(),
        updatedAt: null,
        isCompleted: false,
        completedAt: null,
        notes: _notesController.text.trim(),
        contributions: [],
      );

      final success = await goalProvider.createGoal(goal);
      
      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Goal created successfully! 🎯',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to create goal: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCategoryColor(String id) {
    switch (id) {
      case 'savings': return '#4CAF50';
      case 'debt': return '#F44336';
      case 'investment': return '#9C27B0';
      case 'vacation': return '#FF9800';
      case 'education': return '#2196F3';
      case 'emergency': return '#795548';
      case 'vehicle': return '#607D8B';
      case 'home': return '#3F51B5';
      default: return '#9E9E9E';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Goal'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGoal,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Goal Name',
                hint: 'e.g., Save for Vacation',
                prefixIcon: Icons.flag,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Add a description for your goal',
                prefixIcon: Icons.description,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _targetController,
                label: 'Target Amount',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'] as String,
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(category['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deadline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _selectedDeadline != null
                                    ? _selectedDeadline!.toLocal().toString().split(' ')[0]
                                    : 'Select a date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _selectedDeadline != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: _selectedDeadline != null
                                      ? null
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Add any additional notes',
                prefixIcon: Icons.note,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GoalProgressCircle(
                          progress: 0.0,
                          size: 80,
                          strokeWidth: 6,
                          backgroundColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          progressColor: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isEmpty
                                    ? 'Goal Name'
                                    : _nameController.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ${currencyProvider.currentCurrency} ${_targetController.text.isEmpty ? '0.00' : _targetController.text}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Progress: 0%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                onPressed: _isLoading ? null : _saveGoal,
                text: 'Create Goal',
                isLoading: _isLoading,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.flag,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
