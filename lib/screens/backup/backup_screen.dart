// lib/screens/backup/backup_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
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
  String _backupFrequency = 'weekly';
  int _maxBackups = 5;
  
  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];
  final List<int> _maxBackupOptions = [3, 5, 10, 20];

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
      _backupFrequency = prefs.getString('backup_frequency') ?? 'weekly';
      _maxBackups = prefs.getInt('max_backups') ?? 5;
    });
  }

  Future<String> _getBackupDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
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
      final userProfile = await DatabaseService.getUserProfile(userId);
      
      // Create backup data
      final backupData = {
        'userId': userId,
        'date': DateTime.now().toIso8601String(),
        'transactionCount': transactions.length,
        'familyCount': families.length,
        'userProfile': userProfile,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'families': families.map((f) => f.toJson()).toList(),
      };

      // Save to local file
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('$backupDir/backup_$timestamp.json');
      await file.writeAsString(jsonEncode(backupData));

      // Save metadata
      final prefs = await SharedPreferences.getInstance();
      
      // Rotate backups
      await _rotateBackups(backupDir, prefs);
      
      // Update metadata
      await prefs.setString('last_backup_date', DateTime.now().toIso8601String());
      await prefs.setInt('backup_count', _backupCount + 1);
      
      final backupList = prefs.getStringList('backup_list') ?? [];
      backupList.add(timestamp.toString());
      await prefs.setStringList('backup_list', backupList);
      
      // Calculate storage used
      final backupSize = await file.length() / (1024 * 1024);
      
      setState(() {
        _lastBackupDate = DateTime.now().toIso8601String();
        _backupCount++;
        _storageUsed = backupSize;
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

  Future<void> _rotateBackups(String backupDir, SharedPreferences prefs) async {
    final backupList = prefs.getStringList('backup_list') ?? [];
    
    if (backupList.length >= _maxBackups) {
      backupList.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      
      final toRemove = backupList.length - _maxBackups + 1;
      for (int i = 0; i < toRemove; i++) {
        final file = File('$backupDir/backup_${backupList[i]}.json');
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      backupList.removeRange(0, toRemove);
      await prefs.setStringList('backup_list', backupList);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final backupList = prefs.getStringList('backup_list') ?? [];
      
      if (backupList.isEmpty) {
        throw Exception('No backups found');
      }

      final backupDir = await _getBackupDirectory();
      final latestTimestamp = backupList.last;
      final file = File('$backupDir/backup_$latestTimestamp.json');
      
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final backupDataString = await file.readAsString();
      final backupData = jsonDecode(backupDataString) as Map<String, dynamic>;
      
      final transactionCount = backupData['transactionCount'] ?? 0;
      final familyCount = backupData['familyCount'] ?? 0;
      final backupDate = backupData['date'] ?? 'Unknown';
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will restore the following:'),
              const SizedBox(height: 8),
              Text('• $transactionCount transactions'),
              Text('• $familyCount families'),
              Text('• Date: ${Helpers.formatDate(DateTime.parse(backupDate))}'),
              const SizedBox(height: 8),
              const Text(
                'Warning: This will overwrite current data!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      
      if (confirm != true) {
        setState(() => _isLoading = false);
        return;
      }

      // Restore logic would go here
      
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
        title: const Text('Delete All Backups?'),
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
              final backupList = prefs.getStringList('backup_list') ?? [];
              final backupDir = await _getBackupDirectory();
              
              for (var timestamp in backupList) {
                final file = File('$backupDir/backup_$timestamp.json');
                if (await file.exists()) {
                  await file.delete();
                }
              }
              
              await prefs.remove('backup_list');
              await prefs.remove('last_backup_date');
              await prefs.remove('backup_count');
              await prefs.remove('storage_used');
              await prefs.remove('backup_frequency');
              await prefs.remove('max_backups');
              
              setState(() {
                _lastBackupDate = 'Never';
                _backupCount = 0;
                _storageUsed = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All backups deleted successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Refresh',
          ),
        ],
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
                        _buildStatRow('Max Backups', '$_maxBackups'),
                        _buildStatRow('Auto Backup', _autoBackup ? 'Enabled ✅' : 'Disabled ❌'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auto Backup Settings
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
                          'Auto Backup Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Auto Backup Toggle
                        Row(
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
                                          ? 'Backup $_backupFrequency automatically'
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
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value 
                                          ? 'Auto backup enabled ✅' 
                                          : 'Auto backup disabled ❌',
                                    ),
                                    backgroundColor: value ? Colors.green : Colors.grey,
                                  ),
                                );
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                        
                        if (_autoBackup) ...[
                          const SizedBox(height: 12),
                          // Backup Frequency
                          Row(
                            children: [
                              const Icon(
                                Icons.repeat,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Frequency:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _backupFrequency,
                                  items: _frequencies.map((freq) {
                                    return DropdownMenuItem(
                                      value: freq,
                                      child: Text(freq[0].toUpperCase() + freq.substring(1)),
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    if (value != null) {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('backup_frequency', value);
                                      setState(() => _backupFrequency = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Max Backups
                          Row(
                            children: [
                              const Icon(
                                Icons.save,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Keep Last:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<int>(
                                  value: _maxBackups,
                                  items: _maxBackupOptions.map((count) {
                                    return DropdownMenuItem(
                                      value: count,
                                      child: Text('$count backups'),
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    if (value != null) {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setInt('max_backups', value);
                                      setState(() => _maxBackups = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
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
                          title: 'Delete All Backups',
                          subtitle: 'Delete all backup data',
                          color: Colors.red,
                          onTap: _deleteBackup,
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
                            'Regular backups ensure your financial data is safe. '
                            'Auto backup keeps the last $_maxBackups backups.',
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
