import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/transaction_model.dart';
import '../../models/goal_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  final TextEditingController _goalNoteController = TextEditingController();

  List<GoalModel> _goals = [];
  double _currentSavings = 0;
  bool _isLoading = true; // ✅ ADDED: Loading state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ✅ CHANGED: Made async and added loading state
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId != null) {
        // ✅ FIXED: Added await to get transactions
        final transactions = await DatabaseService.getUserTransactions(userId);
        double income = 0;
        double expense = 0;
        for (var t in transactions) {
          if (t.type == 'income') {
            income += t.amount ?? 0;
          } else if (t.type == 'expense') {
            expense += t.amount ?? 0;
          }
        }
        _currentSavings = income - expense;

        // Load goals from Hive
        final goalsBox = Hive.box<GoalModel>('goals');
        _goals = goalsBox.values
            .where((g) => g.userId == userId)
            .toList()
            .cast<GoalModel>();
      }
    } catch (e) {
      // Handle error
      print('Error loading goals: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load goals: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGoalDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading // ✅ ADDED: Loading indicator
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return _buildGoalCard(goal);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Savings Goals Yet',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a goal to start saving!',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final totalAmount = goal.totalAmount ?? 0;
    final progress = totalAmount > 0
        ? (_currentSavings / totalAmount).clamp(0.0, 1.0)
        : 0.0;

    final isAchieved = progress >= 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAchieved
                        ? Colors.green.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAchieved ? Icons.flag : Icons.flag_outlined,
                    color: isAchieved ? Colors.green : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name ?? 'Goal',
                        style: AppTheme.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Target: ${Helpers.formatCurrency(totalAmount)}',
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
                if (isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ Achieved',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTheme.captionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${Helpers.formatCurrency(_currentSavings)} / ${Helpers.formatCurrency(totalAmount)}',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: isAchieved ? Colors.green : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            if (goal.note != null) ...[
              const SizedBox(height: 8),
              Text(
                goal.note!,
                style: AppTheme.captionStyle,
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Created: ${Helpers.formatDate(goal.createdAt ?? DateTime.now())}',
                  style: AppTheme.captionStyle.copyWith(
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  onPressed: () => _deleteGoal(goal),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    _goalNameController.clear();
    _goalAmountController.clear();
    _goalNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _goalNameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name *',
                hintText: 'e.g., Vacation Fund',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target Amount *',
                hintText: 'e.g., 5000',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalNoteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note about this goal',
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
            onPressed: _createGoal,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createGoal() async {
    if (_goalNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a goal name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_goalAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a goal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final goal = GoalModel(
      id: Helpers.generateId(),
      userId: userId,
      name: _goalNameController.text.trim(),
      totalAmount: amount,
      note: _goalNoteController.text.trim().isEmpty
          ? null
          : _goalNoteController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final goalsBox = Hive.box<GoalModel>('goals');
      await goalsBox.add(goal);

      await _loadData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal created successfully! 🎯'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.name ?? 'Goal'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final goalsBox = Hive.box<GoalModel>('goals');
        await goalsBox.delete(goal.key);
        await _loadData(); // ✅ Changed to await
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete goal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _goalNoteController.dispose();
    super.dispose();
  }
}
