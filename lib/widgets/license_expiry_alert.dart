import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/services/notification_service.dart';

/// ============================================================================
/// LICENSE EXPIRY ALERT WIDGET
/// ============================================================================
/// 
/// Shows a warning card on the dashboard when driver licenses are 
/// expiring or expired.
/// 
/// Color coding:
/// - Red: Expired licenses
/// - Orange: Expiring within 30 days
/// - Yellow: Expiring within 90 days
/// ============================================================================

class LicenseExpiryAlert extends StatelessWidget {
  final LicenseExpiryStats stats;
  final VoidCallback? onTap;

  const LicenseExpiryAlert({
    Key? key,
    required this.stats,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show if no alerts
    if (!stats.hasAlerts) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getPrimaryColor().withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitle(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),

            // Stats Row
            if (stats.totalAlerts > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (stats.expired > 0)
                    _buildStatBadge(
                      context,
                      '${stats.expired}',
                      'Expired',
                      Colors.red.shade900,
                    ),
                  if (stats.expiringSoon > 0)
                    _buildStatBadge(
                      context,
                      '${stats.expiringSoon}',
                      '< 30 days',
                      Colors.orange.shade800,
                    ),
                  if (stats.expiringLater > 0)
                    _buildStatBadge(
                      context,
                      '${stats.expiringLater}',
                      '< 90 days',
                      Colors.yellow.shade800,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build individual stat badge
  Widget _buildStatBadge(
    BuildContext context,
    String count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  /// Get gradient colors based on severity
  List<Color> _getGradientColors() {
    if (stats.expired > 0) {
      return [Colors.red.shade700, Colors.red.shade500];
    } else if (stats.expiringSoon > 0) {
      return [Colors.orange.shade700, Colors.orange.shade500];
    } else {
      return [Colors.amber.shade700, Colors.amber.shade500];
    }
  }

  /// Get primary color based on severity
  Color _getPrimaryColor() {
    if (stats.expired > 0) {
      return Colors.red;
    } else if (stats.expiringSoon > 0) {
      return Colors.orange;
    } else {
      return Colors.amber;
    }
  }

  /// Get icon based on severity
  IconData _getIcon() {
    if (stats.expired > 0) {
      return Icons.error;
    } else if (stats.expiringSoon > 0) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  /// Get title based on severity
  String _getTitle() {
    if (stats.expired > 0) {
      return '⚠️ License Alert!';
    } else if (stats.expiringSoon > 0) {
      return '🔔 License Reminder';
    } else {
      return '📋 License Notice';
    }
  }

  /// Get subtitle based on severity
  String _getSubtitle() {
    List<String> parts = [];
    
    if (stats.expired > 0) {
      parts.add('${stats.expired} expired');
    }
    if (stats.expiringSoon > 0) {
      parts.add('${stats.expiringSoon} expiring soon');
    }
    if (stats.expiringLater > 0) {
      parts.add('${stats.expiringLater} expiring later');
    }
    
    return 'Driver licenses: ${parts.join(', ')}';
  }
}