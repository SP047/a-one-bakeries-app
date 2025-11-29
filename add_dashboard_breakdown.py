#!/usr/bin/env python3
"""Add cash breakdown to dashboard screen"""

import re

file_path = 'lib/screens/dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import
if 'cash_breakdown_screen' not in content:
    import_line = "import 'package:a_one_bakeries_app/screens/cash_breakdown_screen.dart';\n"
    # Find first import statement and add after it
    content = re.sub(
        r"(import 'package:a_one_bakeries_app/screens/stock_screen.dart';\n)",
        r"\1" + import_line,
        content
    )

# 2. Add cash breakdown card before closing the summary section
# Find the closing of summary section
old_closing = '''        ),
      ],
    );
  }

  // ===================== WELCOME & DATE ====================='''

new_closing = '''        ),
        // Cash Breakdown Card
        _buildCashBreakdownCard(),
      ],
    );
  }

  /// Build compact cash breakdown card for dashboard
  Widget _buildCashBreakdownCard() {
    return FutureBuilder<Map<String, double>>(
      future: _dbHelper.getCashBreakdown(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final breakdown = snapshot.data!;
        final total = (breakdown['notes'] ?? 0.0) + (breakdown['r5'] ?? 0.0) + 
                     (breakdown['r2'] ?? 0.0) + (breakdown['r1'] ?? 0.0) + (breakdown['50c'] ?? 0.0);
        final notes = breakdown['notes'] ?? 0.0;
        final coins = (breakdown['r5'] ?? 0.0) + (breakdown['r2'] ?? 0.0) + 
                     (breakdown['r1'] ?? 0.0) + (breakdown['50c'] ?? 0.0);
        final notesPercent = total == 0 ? 0 : ((notes / total) * 100).round();
        final coinsPercent = total == 0 ? 0 : ((coins / total) * 100).round();

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const CashBreakdownScreen(),
          )),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBrown.withOpacity(0.1), AppTheme.successGreen.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryBrown, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(_currencyFormat.format(total), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.primaryBrown),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBreakdownItem(emoji: '💵', label: 'Notes', amount: notes, percentage: notesPercent, color: AppTheme.successGreen)),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(child: _buildBreakdownItem(emoji: '🪙', label: 'Coins', amount: coins, percentage: coinsPercent, color: AppTheme.primaryBrown)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownItem({required String emoji, required String label, required double amount, required int percentage, required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(_currencyFormat.format(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text('$percentage%', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  // ===================== WELCOME & DATE ====================='''

content = content.replace(old_closing, new_closing)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Added cash breakdown card to dashboard!")
