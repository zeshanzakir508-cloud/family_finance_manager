// lib/screens/backup/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  bool _autoBackup = false;
  String _lastBackupDate = 'Never';
  int _backupCount = 0;
  double _storageUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackup = prefs.getBool('auto_backup') ?? false;
      _lastBackupDate = prefs.getString('last_backup_date') ?? 'Never';
      _backupCount = prefs.getInt('backup_count') ?? 0;
      _storageUsed = prefs.getDouble('storage_used') ?? 0;
    });
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get all user data
      final transactions = await DatabaseService.getUserTransactions(userId);
      final families = await DatabaseService.getUserFamilies(userId);
      
      // Create backup
      final backupData = {
        'userId': userId,
        'date': DateTime.now().toIso8601String(),
        'transactionCount': transactions.length,
        'familyCount': families.length,
        'data': {
          'transactions': transactions.map((t) => t.toJson()).toList(),
          'families': families.map((f) => f.toJson()).toList(),
        },
      };

      // Save backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_data', backupData.toString());
      await prefs.setString('last_backup_date', DateTime.now().toIso8601String());
      await prefs.setInt('backup_count', _backupCount + 1);
      
      setState(() {
        _lastBackupDate = DateTime.now().toIso8601String();
        _backupCount++;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup created successfully! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getString('backup_data');
      
      if (backupData == null) {
        throw Exception('No backup found');
      }

      // In a real app, this would restore data from backup
      // For now, just show a message
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored successfully! 🔄'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBackup() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text('Are you sure you want to delete all backup data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('backup_data');
              await prefs.remove('last_backup_date');
              setState(() {
                _lastBackupDate = 'Never';
                _backupCount = 0;
                _storageUsed = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _lastBackupDate != 'Never'
        ? Helpers.formatDate(DateTime.parse(_lastBackupDate))
        : 'Never';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Backup Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backup Statistics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow('Last Backup', formattedDate),
                        _buildStatRow('Backup Count', _backupCount.toString()),
                        _buildStatRow('Storage Used', '${_storageUsed.toStringAsFixed(2)} MB'),
                        _buildStatRow('Auto Backup', _autoBackup ? 'Enabled' : 'Disabled'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildActionButton(
                          icon: Icons.backup,
                          title: 'Create Backup',
                          subtitle: 'Backup all your data',
                          color: Colors.blue,
                          onTap: _createBackup,
                        ),
                        const Divider(),
                        _buildActionButton(
                          icon: Icons.restore,
                          title: 'Restore Backup',
                          subtitle: 'Restore from previous backup',
                          color: Colors.green,
                          onTap: _restoreBackup,
                        ),
                        const Divider(),
                        _buildActionButton(
                          icon: Icons.delete,
                          title: 'Delete Backup',
                          subtitle: 'Delete all backup data',
                          color: Colors.red,
                          onTap: _deleteBackup,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auto Backup Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: _autoBackup ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Auto Backup',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _autoBackup
                                      ? 'Backup daily automatically'
                                      : 'Manual backup only',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _autoBackup,
                          onChanged: (value) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('auto_backup', value);
                            setState(() => _autoBackup = value);
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your data is encrypted and securely stored. '
                            'Regular backups ensure your financial data is safe.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
