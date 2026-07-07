// lib/screens/goals/goal_contribution_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/goal_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_snackbar.dart';

class GoalContributionScreen extends StatefulWidget {
  final String goalId;

  const GoalContributionScreen({
    Key? key,
    required this.goalId,
  }) : super(key: key);

  @override
  State<GoalContributionScreen> createState() => _GoalContributionScreenState();
}

class _GoalContributionScreenState extends State<GoalContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  GoalModel? _goal;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadGoal() {
    final goalProvider = context.read<GoalProvider>();
    final goal = goalProvider.goals.firstWhere(
      (g) => g.id == widget.goalId,
      orElse: () => throw Exception('Goal not found'),
    );
    setState(() {
      _goal = goal;
      _isLoading = false;
    });
  }

  void _quickAddAmount(double amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.show(
        context,
        'Please enter a valid amount',
        isError: true,
      );
      return;
    }

    // Check if amount exceeds remaining target
    final remaining = (_goal?.targetAmount ?? 0) - (_goal?.currentAmount ?? 0);
    if (amount > remaining) {
      CustomSnackBar.show(
        context,
        'Amount exceeds remaining target (${remaining.toStringAsFixed(2)})',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final goalProvider = context.read<GoalProvider>();
      final success = await goalProvider.addContribution(
        widget.goalId,
        amount,
        note: _noteController.text.trim(),
      );

      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Contribution added successfully! 🎯',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to add contribution: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Contribution')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Contribution')),
        body: const Center(child: Text('Goal not found')),
      );
    }

    final goal = _goal!;
    final progress = goal.progress;
    final remaining = (goal.targetAmount ?? 0) - (goal.currentAmount ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contribution'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submitContribution,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
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
              // Goal summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${currencyProvider.currentCurrency} ${goal.targetAmount?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Saved: ${currencyProvider.currentCurrency} ${goal.currentAmount?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining: ${currencyProvider.currentCurrency} ${remaining.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: remaining > 0 ? Colors.blue[600] : Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                        color: progress >= 1 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick amount buttons
              const Text(
                'Quick Amounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmountButton(10),
                  _buildQuickAmountButton(25),
                  _buildQuickAmountButton(50),
                  _buildQuickAmountButton(100),
                  _buildQuickAmountButton(200),
                  _buildQuickAmountButton(500),
                ],
              ),
              const SizedBox(height: 16),

              // Amount input
              CustomTextField(
                controller: _amountController,
                label: 'Amount',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > remaining) {
                    return 'Amount exceeds remaining target';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Note
              CustomTextField(
                controller: _noteController,
                label: 'Note (Optional)',
                hint: 'e.g., Monthly savings, Bonus',
                prefixIcon: Icons.note,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Submit button
              CustomButton(
                onPressed: _isSaving ? null : _submitContribution,
                text: 'Add Contribution',
                isLoading: _isSaving,
                type: ButtonType.primary,
                size: ButtonSize.large,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    return OutlinedButton(
      onPressed: () => _quickAddAmount(amount),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        '${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
