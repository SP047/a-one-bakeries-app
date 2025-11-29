import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:intl/intl.dart';

/// Cash Breakdown Screen
/// 
/// Shows detailed breakdown of total cash by denomination

class CashBreakdownScreen extends StatefulWidget {
  const CashBreakdownScreen({super.key});

  @override
  State<CashBreakdownScreen> createState() => _CashBreakdownScreenState();
}

class _CashBreakdownScreenState extends State<CashBreakdownScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');
  
  Map<String, double>? _breakdown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final breakdown = await _dbHelper.getCashBreakdown();
      setState(() {
        _breakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cash breakdown: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  double _getTotal() {
    if (_breakdown == null) return 0.0;
    return (_breakdown!['notes'] ?? 0.0) +
           (_breakdown!['r5'] ?? 0.0) +
           (_breakdown!['r2'] ?? 0.0) +
           (_breakdown!['r1'] ?? 0.0) +
           (_breakdown!['50c'] ?? 0.0);
  }

  double _getTotalCoins() {
    if (_breakdown == null) return 0.0;
    return (_breakdown!['r5'] ?? 0.0) +
           (_breakdown!['r2'] ?? 0.0) +
           (_breakdown!['r1'] ?? 0.0) +
           (_breakdown!['50c'] ?? 0.0);
  }

  String _getPercentage(double amount, double total) {
    if (total == 0) return '0%';
    return '${((amount / total) * 100).toStringAsFixed(1)}%';
  }

  Widget _buildDenominationCard({
    required String label,
    required String emoji,
    required double amount,
    required double total,
    required Color color,
    bool isLarge = false,
  }) {
    final percentage = _getPercentage(amount, total);
    final barWidth = total == 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);

    return Card(
      elevation: isLarge ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: EdgeInsets.all(isLarge ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: isLarge ? 32 : 24),
                  ),
                ),
                const SizedBox(width: 16),
                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isLarge ? 18 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (!isLarge) const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(amount),
                        style: TextStyle(
                          fontSize: isLarge ? 32 : 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    percentage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: barWidth,
                minHeight: isLarge ? 12 : 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinRow({
    required String label,
    required String denomination,
    required double amount,
    required double total,
    required Color color,
  }) {
    final percentage = _getPercentage(amount, total);
    final barWidth = total == 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Denomination badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    denomination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barWidth,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cash Breakdown'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final total = _getTotal();
    final notes = _breakdown?['notes'] ?? 0.0;
    final totalCoins = _getTotalCoins();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cash Breakdown'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBreakdown,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Cash Card - Hero Element
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.successGreen,
                    AppTheme.successGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Total Cash on Hand',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currencyFormat.format(total),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Breakdown by Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // Paper Money Card
            _buildDenominationCard(
              label: 'Paper Money',
              emoji: '💵',
              amount: notes,
              total: total,
              color: AppTheme.successGreen,
              isLarge: true,
            ),
            const SizedBox(height: 16),

            // Coins Card
            _buildDenominationCard(
              label: 'Total Coins',
              emoji: '🪙',
              amount: totalCoins,
              total: total,
              color: AppTheme.primaryBrown,
              isLarge: true,
            ),
            const SizedBox(height: 28),

            // Coin Breakdown Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  const Text(
                    '🪙',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coin Denominations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCoinRow(
                      label: 'R5 Coins',
                      denomination: 'R5',
                      amount: _breakdown?['r5'] ?? 0.0,
                      total: total,
                      color: const Color(0xFF8B4513),
                    ),
                    _buildCoinRow(
                      label: 'R2 Coins',
                      denomination: 'R2',
                      amount: _breakdown?['r2'] ?? 0.0,
                      total: total,
                      color: const Color(0xFFA0522D),
                    ),
                    _buildCoinRow(
                      label: 'R1 Coins',
                      denomination: 'R1',
                      amount: _breakdown?['r1'] ?? 0.0,
                      total: total,
                      color: const Color(0xFFB8860B),
                    ),
                    _buildCoinRow(
                      label: '50c Coins',
                      denomination: '50c',
                      amount: _breakdown?['50c'] ?? 0.0,
                      total: total,
                      color: const Color(0xFFCD853F),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cash breakdown shows net amount (income - expenses) by denomination',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
