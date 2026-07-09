// lib/screens/goals/goal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/goal_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/custom_text_field.dart';
import 'widgets/goal_progress_circle.dart';
import 'widgets/goal_milestone_widget.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({
    Key? key,
    required this.goalId,
  }) : super(key: key);

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  GoalModel? _goal;
  bool _isLoading = true;
  bool _isContributing = false;
  final _contributionController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  @override
  void dispose() {
    _contributionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadGoal() {
    final goalProvider = context.read<GoalProvider>();
    final goal = goalProvider.goals.firstWhere(
      (g) => g.id == widget.goalId,
      orElse: () => goalProvider.completedGoals.firstWhere(
        (g) => g.id == widget.goalId,
        orElse: () => throw Exception('Goal not found'),
      ),
    );
    setState(() {
      _goal = goal;
      _isLoading = false;
    });
  }

  Future<void> _refreshGoal() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    await context.read<GoalProvider>().loadGoals(auth.userId);
    _loadGoal();
  }

  void _showContributionDialog() {
    _contributionController.clear();
    _noteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _contributionController,
              label: 'Amount',
              hint: '0.00',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _noteController,
              label: 'Note (Optional)',
              hint: 'e.g., Monthly savings',
              prefixIcon: Icons.note,
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
            onPressed: () async {
              final amount = double.tryParse(_contributionController.text.trim());
              if (amount == null || amount <= 0) {
                CustomSnackBar.show(
                  context,
                  'Please enter a valid amount',
                  isError: true,
                );
                return;
              }
              Navigator.pop(context);
              await _addContribution(amount, _noteController.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addContribution(double amount, String note) async {
    setState(() => _isContributing = true);

    try {
      final goalProvider = context.read<GoalProvider>();
      final success = await goalProvider.addContribution(
        widget.goalId,
        amount,
        note: note,
      );

      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Contribution added! 🎯',
        );
        await _refreshGoal();
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
      if (mounted) setState(() => _isContributing = false);
    }
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
          'Are you sure you want to delete this goal? This action cannot be undone.',
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
        final goalProvider = context.read<GoalProvider>();
        final success = await goalProvider.deleteGoal(widget.goalId);
        if (success && mounted) {
          CustomSnackBar.show(
            context,
            'Goal deleted successfully',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to delete: ${e.toString()}',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: Text('Goal not found')),
      );
    }

    final goal = _goal!;
    final progress = goal.progress;
    final isCompleted = goal.isAchieved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit goal
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshGoal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isCompleted ? Colors.green : Theme.of(context).primaryColor,
                      isCompleted ? Colors.green.shade700 : Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      goal.category ?? 'Goal',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (isCompleted) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Completed 🎉',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                goal.name ?? 'Goal', // ✅ FIXED: Null safety
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (goal.description?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 4),
                                Text(
                                  goal.description!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        GoalProgressCircle(
                          progress: progress,
                          size: 80,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          progressColor: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${currencyProvider.currentCurrency} ${goal.targetAmount?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Saved',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${currencyProvider.currentCurrency} ${goal.currentAmount?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (goal.deadline != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Deadline: ${goal.deadline!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (!isCompleted) ...[
                            Text(
                              goal.isOverdue ? '⚠️ Overdue' : '✅ On Track',
                              style: TextStyle(
                                color: goal.isOverdue ? Colors.red.shade300 : Colors.green.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contributions section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contributions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isCompleted)
                    CustomButton(
                      onPressed: _isContributing ? null : _showContributionDialog,
                      text: 'Add',
                      type: ButtonType.primary,
                      size: ButtonSize.small,
                      icon: Icons.add,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (goal.contributions == null || goal.contributions!.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No contributions yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goal.contributions!.length,
                  itemBuilder: (context, index) {
                    final contribution = goal.contributions![index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      title: Text(
                        '${currencyProvider.currentCurrency} ${contribution.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        contribution.note ?? 'No note',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        contribution.date.toLocal().toString().split(' ')[0],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Milestones
              if (!isCompleted && progress > 0) ...[
                const Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GoalMilestoneWidget(
                  progress: progress,
                  target: goal.targetAmount ?? 0,
                  currency: currencyProvider.currentCurrency,
                ),
                const SizedBox(height: 24),
              ],

              // Delete button (if completed)
              if (isCompleted)
                CustomButton(
                  onPressed: _deleteGoal,
                  text: 'Delete Goal',
                  type: ButtonType.danger,
                  size: ButtonSize.medium,
                  icon: Icons.delete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
