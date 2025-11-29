import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/services/backup_service.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';

/// ============================================================================
/// Backup History Dialog
/// ============================================================================
/// Shows list of available backups with restore/delete actions
/// ============================================================================

class BackupHistoryDialog extends StatefulWidget {
  const BackupHistoryDialog({super.key});

  @override
  State<BackupHistoryDialog> createState() => _BackupHistoryDialogState();
}

class _BackupHistoryDialogState extends State<BackupHistoryDialog> {
  final BackupService _backupService = BackupService();
  List<BackupInfo>? _backups;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final backups = await _backupService.listBackups();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: Text(
          'This will replace all current data with the backup from ${backup.formattedDate}.\n\n'
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _backupService.restoreBackup(backup.filePath);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close backup history dialog
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Backup restored successfully! Please restart the app.'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to restore backup: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: Text(
          'Delete backup from ${backup.formattedDate}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _backupService.deleteBackup(backup.filePath);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Backup deleted'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      
      // Reload backups
      _loadBackups();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to delete backup: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.history, size: 28, color: AppTheme.darkBrown),
                const SizedBox(width: 12),
                const Text(
                  'Backup History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBrown,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _backups == null
                  ? 'Loading backups...'
                  : '${_backups!.length} backup(s) available',
              style: TextStyle(
                color: AppTheme.darkBrown.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppTheme.errorRed,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading backups',
                                style: TextStyle(
                                  color: AppTheme.darkBrown.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorRed,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _backups!.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.backup_outlined,
                                    size: 64,
                                    color: AppTheme.darkBrown.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No backups found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.darkBrown.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create your first backup from Settings',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.darkBrown.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _backups!.length,
                              itemBuilder: (context, index) {
                                final backup = _backups![index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBrown.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.backup,
                                            color: AppTheme.darkBrown,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                backup.formattedDate,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                backup.formattedSize,
                                                style: TextStyle(
                                                  color: AppTheme.darkBrown.withOpacity(0.6),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Actions
                                        Row(
                                          children: [
                                            // Restore button
                                            ElevatedButton.icon(
                                              onPressed: () => _restoreBackup(backup),
                                              icon: const Icon(Icons.restore, size: 18),
                                              label: const Text('Restore'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.darkBrown,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Delete button
                                            IconButton(
                                              onPressed: () => _deleteBackup(backup),
                                              icon: const Icon(Icons.delete),
                                              color: AppTheme.errorRed,
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
