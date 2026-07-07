// lib/screens/dashboard/widgets/quick_actions_widget.dart
import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionItem(
                context,
                icon: Icons.add_circle,
                label: 'Add Income',
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/add_income');
                },
              ),
              _buildActionItem(
                context,
                icon: Icons.remove_circle,
                label: 'Add Expense',
                color: Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, '/add_expense');
                },
              ),
              _buildActionItem(
                context,
                icon: Icons.analytics,
                label: 'Reports',
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/reports');
                },
              ),
              _buildActionItem(
                context,
                icon: Icons.person,
                label: 'Profile',
                color: Colors.purple,
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
