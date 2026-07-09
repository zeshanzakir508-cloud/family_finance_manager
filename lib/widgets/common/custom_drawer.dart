// lib/widgets/common/custom_drawer.dart
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final List<DrawerItem> items;
  final VoidCallback? onLogout;

  const CustomDrawer({
    Key? key,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    required this.items,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: userPhotoUrl != null
                      ? NetworkImage(userPhotoUrl!)
                      : null,
                  child: userPhotoUrl == null
                      ? Text(
                          userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  userName ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail ?? 'guest@example.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isDark ? Colors.white : Colors.grey[700],
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    item.onTap();
                  },
                );
              },
            ),
          ),
          // Logout
          if (onLogout != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLogout?.call();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
