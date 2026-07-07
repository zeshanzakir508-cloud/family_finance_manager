// lib/screens/goals/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/goal_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/goal_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final goalProvider = context.read<GoalProvider>();
    
    if (auth.isAuthenticated) {
      await goalProvider.loadGoals(auth.userId);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/add_goal');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildContent(
              context,
              goalProvider.goals,
              currencyProvider.currentCurrency,
              isDark,
              false,
            ),
            _buildContent(
              context,
              goalProvider.completedGoals,
              currencyProvider.currentCurrency,
              isDark,
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<GoalModel> goals,
    String currency,
    bool isDark,
    bool isCompleted,
  ) {
    if (goalProvider.isLoading) {
      return const LoadingWidget();
    }

    if (goalProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load goals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              goalProvider.error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (goals.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.flag,
        title: isCompleted ? 'No Completed Goals' : 'No Goals Yet',
        description: isCompleted
            ? 'Your completed goals will appear here.'
            : 'Set a financial goal to start saving!',
        buttonText: isCompleted ? null : 'Create Goal',
        onPressed: isCompleted
            ? null
            : () {
                Navigator.pushNamed(context, '/add_goal');
              },
      );
    }

    // Calculate total progress
    double totalTarget = 0.0;
    double totalCurrent = 0.0;
    for (var goal in goals) {
      totalTarget += goal.targetAmount ?? 0.0;
      totalCurrent += goal.currentAmount ?? 0.0;
    }
    final totalProgress = totalTarget > 0 ? totalCurrent / totalTarget : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompleted ? 'Completed Goals' : 'Active Goals Summary',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${goals.length} Goal${goals.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: $currency ${totalTarget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isCompleted) ...[
                        Text(
                          '${(totalProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Saved: $currency ${totalCurrent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (isCompleted)
                        Text(
                          'Completed! 🎉',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalProgress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Goal list
        ...goals.map((goal) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GoalCard(
              goal: goal,
              currency: currency,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/goal_detail',
                  arguments: goal.id,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
