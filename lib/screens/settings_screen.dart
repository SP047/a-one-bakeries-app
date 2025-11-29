import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/screens/notification_settings_screen.dart';
import 'package:a_one_bakeries_app/services/backup_service.dart';
import 'package:a_one_bakeries_app/widgets/backup_history_dialog.dart';
import 'package:a_one_bakeries_app/widgets/export_data_dialog.dart';

/// Settings Screen
/// 
/// Main settings hub for the app with various configuration options

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  int _backupCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBackupCount();
  }

  Future<void> _loadBackupCount() async {
    try {
      final backups = await _backupService.listBackups();
      setState(() {
        _backupCount = backups.length;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _createBackup() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final backupPath = await _backupService.createBackup();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Backup created successfully!\n$backupPath'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Reload backup count
      _loadBackupCount();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create backup: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _showBackupHistory() async {
    await showDialog(
      context: context,
      builder: (context) => const BackupHistoryDialog(),
    );
    
    // Reload backup count after dialog closes
    _loadBackupCount();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportDataDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App Info Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bakery_dining,
                    size: 64,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A-One Bakeries',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_active,
            title: 'Notification Settings',
            subtitle: 'Manage reminders and alerts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Data Management Section
          _buildSectionHeader(context, 'Data Management'),
          _buildSettingsTile(
            context,
            icon: Icons.backup,
            title: 'Create Backup',
            subtitle: 'Backup all your data',
            onTap: _createBackup,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.history,
            title: 'Backup History',
            subtitle: _backupCount > 0 
                ? '$_backupCount backup(s) available'
                : 'No backups yet',
            onTap: _showBackupHistory,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.file_download,
            title: 'Export Data',
            subtitle: 'Export to CSV or JSON',
            onTap: _showExportDialog,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.storage,
            title: 'Database Info',
            subtitle: 'View database statistics',
            onTap: () {
              _showDatabaseInfo(context);
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'About App',
            subtitle: 'Learn more about this app',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help using the app',
            onTap: () {
              _showComingSoon(context, 'Help & Support');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryBrown,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBrown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryBrown),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showDatabaseInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: AppTheme.primaryBrown),
            SizedBox(width: 8),
            Text('Database Info'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Database Version: 6'),
            SizedBox(height: 8),
            Text('Tables:'),
            Text('  • Stock Items & Movements'),
            Text('  • Employees & Credits'),
            Text('  • Vehicles & KM Tracking'),
            Text('  • Orders & Items'),
            Text('  • Finance Records'),
            Text('  • Suppliers & Invoices'),
            Text('  • Driver Licenses'),
            Text('  • Service Records'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bakery_dining, color: AppTheme.primaryBrown),
            SizedBox(width: 8),
            Text('About'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A-One Bakeries Management App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'A comprehensive business management solution for tracking stock, orders, employees, vehicles, and finances.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Stock Management'),
            Text('• Order Tracking'),
            Text('• Employee Management'),
            Text('• Vehicle & KM Tracking'),
            Text('• Financial Records'),
            Text('• Automated Reminders'),
            Text('• Data Backup & Export'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.construction, color: AppTheme.secondaryOrange),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature feature is coming in a future update!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
