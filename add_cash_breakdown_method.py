#!/usr/bin/env python3
"""Add getCashBreakdown method to database_helper.dart"""

file_path = 'lib/database/database_helper.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Method to add
cash_breakdown_method = '''
  /// Get cash breakdown from all income records
  /// Returns total notes and coin denominations
  Future<Map<String, double>> getCashBreakdown() async {
    final db = await database;
    
    // Query all income records
    final result = await db.rawQuery(\'\'\'
      SELECT 
        SUM(notes) as totalNotes,
        SUM(amountR5) as totalR5,
        SUM(amountR2) as totalR2,
        SUM(amountR1) as totalR1,
        SUM(amount50c) as total50c
      FROM income
    \'\'\');
    
    if (result.isEmpty || result.first['totalNotes'] == null) {
      return {
        'notes': 0.0,
        'r5': 0.0,
        'r2': 0.0,
        'r1': 0.0,
        '50c': 0.0,
      };
    }
    
    final data = result.first;
    return {
      'notes': (data['totalNotes'] as num?)?.toDouble() ?? 0.0,
      'r5': (data['totalR5'] as num?)?.toDouble() ?? 0.0,
      'r2': (data['totalR2'] as num?)?.toDouble() ?? 0.0,
      'r1': (data['totalR1'] as num?)?.toDouble() ?? 0.0,
      '50c': (data['total50c'] as num?)?.toDouble() ?? 0.0,
    };
  }
'''

# Find insertion point - after getMoneyOnHand method
insertion_marker = "  /// Get today's income"

if insertion_marker in content:
    content = content.replace(insertion_marker, cash_breakdown_method + '\n' + insertion_marker)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Added getCashBreakdown() method to database_helper.dart!")
else:
    print("❌ Could not find insertion point")
