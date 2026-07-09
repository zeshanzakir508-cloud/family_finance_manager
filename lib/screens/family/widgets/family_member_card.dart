// lib/screens/family/widgets/family_member_card.dart
import 'package:flutter/material.dart';
import '../../../models/family_model.dart';

class FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final bool isAdmin;
  final bool isCurrentUser;
  final VoidCallback? onRemove;
  final VoidCallback? onPromote;

  const FamilyMemberCard({
    Key? key,
    required this.member,
    required this.isAdmin,
    required this.isCurrentUser,
    this.onRemove,
    this.onPromote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? Colors.blue.withOpacity(0.2)
              : isDark
                  ? Colors.grey[700]
                  : Colors.grey[300],
          child: Text(
            member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAdmin ? Colors.blue : null,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isAdmin)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          member.email ?? '', // ✅ FIXED: Null safety
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPromote != null)
              IconButton(
                icon: const Icon(
                  Icons.admin_panel_settings,
                  size: 18,
                ),
                color: Colors.blue,
                onPressed: onPromote,
                tooltip: 'Make admin',
              ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 18,
                ),
                color: Colors.red,
                onPressed: onRemove,
                tooltip: 'Remove member',
              ),
          ],
        ),
      ),
    );
  }
}
