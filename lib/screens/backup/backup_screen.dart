import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../models/backup_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  List<BackupModel> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  void _loadBackups() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId != null) {
      _backups = await BackupService.getBackups(userId);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackupInfo(),
                  const SizedBox(height: 24),
                  _buildActions(),
                  const SizedBox(height: 24),
                  _buildBackupHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildBackupInfo() {
    final latestBackup = _backups.isNotEmpty ? _backups.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup Information',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.folder,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Backup',
                      style: AppTheme.captionStyle,
                    ),
                    Text(
                      latestBackup?.formattedDate ?? 'No backup yet',
                      style: AppTheme.bodyStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.storage,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Size',
                      style: AppTheme.captionStyle,
                    ),
                    Text(
                      latestBackup?.formattedSize ?? '0 MB',
                      style: AppTheme.bodyStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Records',
                      style: AppTheme.captionStyle,
                    ),
                    Text(
                      latestBackup?.summary ?? 'No data',
                      style: AppTheme.bodyStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _createBackup,
            icon: const Icon(Icons.backup),
            label: const Text('Backup Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _restoreBackup,
            icon: const Icon(Icons.restore),
            label: const Text('Restore'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupHistory() {
    if (_backups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.backup_outlined,
                size: 64,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No backups yet',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Backup Now" to create your first backup',
                style: AppTheme.captionStyle,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup History',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _backups.length > 10 ? 10 : _backups.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final backup = _backups[index];
            return _buildBackupTile(backup);
          },
        ),
        if (_backups.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing 10 of ${_backups.length} backups',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildBackupTile(BackupModel backup) {
    return ListTile(
      leading: Icon(
        Icons.backup,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        backup.fileName ?? 'Backup',
        style: AppTheme.bodyStyle,
      ),
      subtitle: Text(
        '${backup.formattedDate} • ${backup.formattedSize} • ${backup.transactionCount} transactions',
        style: AppTheme.captionStyle,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _deleteBackup(backup),
        tooltip: 'Delete',
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup from ${backup.formattedDate}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  void _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final backup = await BackupService.createBackup(userId);

    setState(() {
      _isLoading = false;
    });

    if (backup != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBackups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create backup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _restoreBackup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'Restoring will replace all current data with the backup data. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No backups available to restore'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final latestBackup = _backups.first;

    setState(() {
      _isLoading = true;
    });

    final success = await BackupService.restoreBackup(
      latestBackup.filePath!,
      userId,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBackups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore backup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteBackup(BackupModel backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text(
          'Delete backup from ${backup.formattedDate}?',
        ),
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

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    final success = await BackupService.deleteBackupFile(backup);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBackups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete backup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
