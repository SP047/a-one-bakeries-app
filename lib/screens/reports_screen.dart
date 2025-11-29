import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/screens/income_report_screen.dart';
import 'package:a_one_bakeries_app/screens/financial_summary_screen.dart';

/// Main Reports Screen
/// 
/// Central hub for accessing all report types

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            'Business Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate and export comprehensive business reports',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Stock Reports Section
          _buildSectionHeader(context, 'Inventory & Stock'),
          _buildReportCard(
            context,
            icon: Icons.inventory_2,
            title: 'Stock Movement Report',
            description: 'Track all stock additions and usage',
            color: AppTheme.primaryBrown,
            onTap: () => _showComingSoon(context, 'Stock Movement Report'),
          ),
          _buildReportCard(
            context,
            icon: Icons.local_shipping,
            title: 'Supplier Report',
            description: 'Supplier transactions and history',
            color: Colors.blue,
            onTap: () => _showComingSoon(context, 'Supplier Report'),
          ),
          const SizedBox(height: 16),

          // Operations Reports Section
          _buildSectionHeader(context, 'Operations'),
          _buildReportCard(
            context,
            icon: Icons.delivery_dining,
            title: 'Driver/Vehicle Orders',
            description: 'Daily orders by driver and assigned vehicle',
            color: AppTheme.secondaryOrange,
            onTap: () => _showComingSoon(context, 'Driver/Vehicle Orders Report'),
          ),
          const SizedBox(height: 16),

          // Employee Reports Section
          _buildSectionHeader(context, 'Employees'),
          _buildReportCard(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Employee Credits',
            description: 'Track employee credit balances',
            color: Colors.purple,
            onTap: () => _showComingSoon(context, 'Employee Credits Report'),
          ),
          const SizedBox(height: 16),

          // Financial Reports Section
          _buildSectionHeader(context, 'Financial'),
          _buildReportCard(
            context,
            icon: Icons.trending_up,
            title: 'Income Report',
            description: 'Individual and combined income tracking',
            color: AppTheme.successGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IncomeReportScreen()),
              );
            },
          ),
          _buildReportCard(
            context,
            icon: Icons.trending_down,
            title: 'Expense Report',
            description: 'Individual and combined expense tracking',
            color: AppTheme.errorRed,
            onTap: () => _showComingSoon(context, 'Expense Report'),
          ),
          _buildReportCard(
            context,
            icon: Icons.assessment,
            title: 'Financial Summary',
            description: 'Combined income and expense analysis',
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FinancialSummaryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBrown,
            ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkBrown.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.darkBrown),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String reportName) {
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
        content: Text('$reportName is being implemented...'),
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
