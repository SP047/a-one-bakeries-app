#!/usr/bin/env python3
"""Update getCashBreakdown to include expenses"""

file_path = 'lib/database/database_helper.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the getCashBreakdown method
old_method = '''  /// Get cash breakdown from all income records
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
  }'''

new_method = '''  /// Get cash breakdown (income - expenses)
  /// Returns actual cash on hand by denomination
  Future<Map<String, double>> getCashBreakdown() async {
    final db = await database;
    
    // Get total income by denomination
    final incomeResult = await db.rawQuery(\'\'\'
      SELECT 
        COALESCE(SUM(notes), 0) as totalNotes,
        COALESCE(SUM(amountR5), 0) as totalR5,
        COALESCE(SUM(amountR2), 0) as totalR2,
        COALESCE(SUM(amountR1), 0) as totalR1,
        COALESCE(SUM(amount50c), 0) as total50c
      FROM income
    \'\'\');
    
    // Get total expenses by denomination
    final expenseResult = await db.rawQuery(\'\'\'
      SELECT 
        COALESCE(SUM(notes), 0) as totalNotes,
        COALESCE(SUM(amountR5), 0) as totalR5,
        COALESCE(SUM(amountR2), 0) as totalR2,
        COALESCE(SUM(amountR1), 0) as totalR1,
        COALESCE(SUM(amount50c), 0) as total50c
      FROM expenses
    \'\'\');
    
    final incomeData = incomeResult.first;
    final expenseData = expenseResult.first;
    
    // Calculate net amounts (income - expenses)
    return {
      'notes': ((incomeData['totalNotes'] as num?)?.toDouble() ?? 0.0) - 
               ((expenseData['totalNotes'] as num?)?.toDouble() ?? 0.0),
      'r5': ((incomeData['totalR5'] as num?)?.toDouble() ?? 0.0) - 
            ((expenseData['totalR5'] as num?)?.toDouble() ?? 0.0),
      'r2': ((incomeData['totalR2'] as num?)?.toDouble() ?? 0.0) - 
            ((expenseData['totalR2'] as num?)?.toDouble() ?? 0.0),
      'r1': ((incomeData['totalR1'] as num?)?.toDouble() ?? 0.0) - 
            ((expenseData['totalR1'] as num?)?.toDouble() ?? 0.0),
      '50c': ((incomeData['total50c'] as num?)?.toDouble() ?? 0.0) - 
             ((expenseData['total50c'] as num?)?.toDouble() ?? 0.0),
    };
  }'''

content = content.replace(old_method, new_method)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Updated getCashBreakdown() to include expenses!")
