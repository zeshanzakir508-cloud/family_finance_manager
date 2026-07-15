// lib/screens/settings/backup_restore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // ✅ Uses AppAuthProvider
import '../../providers/theme_provider.dart';
import '../../models/backup_model.dart';
import '../../services/backup_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_snackbar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({Key? key}) : super(key: key);

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  List<BackupModel> _backups = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: AuthProvider → AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      _backups = await BackupService.getBackups(auth.userId);
      _backups.sort((a, b) => b.backupDate!.compareTo(a.backupDate!));
    } catch (e) {
      print('Error loading backups: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreating = true);

    try {
      // ✅ FIXED: AuthProvider → AppAuthProvider
      final auth = context.read<AppAuthProvider>();
      final backup = await BackupService.createBackup(auth.userId);
      
      if (backup != null) {
        setState(() {
          _backups.insert(0, backup);
        });
        CustomSnackBar.show(
          context,
          'Backup created successfully! 📦',
        );
      } else {
        CustomSnackBar.show(
          context,
          'Failed to create backup',
          isError: true,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Error: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _restoreBackup(BackupModel backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
          'Restore backup from ${backup.formattedDate}? This will replace all current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        // ✅ FIXED: AuthProvider → AppAuthProvider
        final auth = context.read<AppAuthProvider>();
        final success = await BackupService.restoreBackup(
          backup.filePath!,
          auth.userId,
        );
        
        if (success) {
          CustomSnackBar.show(
            context,
            'Backup restored successfully! 🔄',
          );
          await _loadBackups();
        } else {
          CustomSnackBar.show(
            context,
            'Failed to restore backup',
            isError: true,
          );
        }
      } catch (e) {
        CustomSnackBar.show(
          context,
          'Error: ${e.toString()}',
          isError: true,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBackup(BackupModel backup) async {
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
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await BackupService.deleteBackupFile(backup);
      if (success) {
        setState(() {
          _backups.removeWhere((b) => b.id == backup.id);
        });
        CustomSnackBar.show(
          context,
          'Backup deleted successfully',
        );
      } else {
        CustomSnackBar.show(
          context,
          'Failed to delete backup',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.backup),
            onPressed: _isCreating ? null : _createBackup,
            tooltip: 'Create Backup',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (_backups.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.backup,
        title: 'No Backups',
        description: 'Create your first backup to secure your data.',
        buttonText: 'Create Backup',
        onPressed: _createBackup,
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You have ${_backups.length} backup${_backups.length > 1 ? 's' : ''}. Total size: ${_getTotalSize()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _backups.length,
            itemBuilder: (context, index) {
              final backup = _backups[index];
              final isFirst = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFirst
                        ? Colors.green.withOpacity(0.3)
                        : isDark
                            ? Colors.grey[700]!
                            : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.backup,
                            color: isFirst ? Colors.green : Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                backup.formattedDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                backup.summary,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFirst ? 'Latest' : backup.formattedSize,
                            style: TextStyle(
                              fontSize: 10,
                              color: isFirst ? Colors.green : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            onPressed: () => _restoreBackup(backup),
                            text: 'Restore',
                            type: ButtonType.outline,
                            size: ButtonSize.small,
                            icon: Icons.restore,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          onPressed: () => _deleteBackup(backup),
                          text: 'Delete',
                          type: ButtonType.danger,
                          size: ButtonSize.small,
                          icon: Icons.delete,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getTotalSize() {
    double total = 0;
    for (var backup in _backups) {
      total += backup.fileSize ?? 0;
    }
    if (total > 1024) {
      return '${(total / 1024).toStringAsFixed(1)} GB';
    }
    return '${total.toStringAsFixed(1)} MB';
  }
}
