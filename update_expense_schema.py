#!/usr/bin/env python3
"""
Update expenses table schema to add notes and coins fields
"""

def update_database_helper():
    file_path = 'lib/database/database_helper.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find and replace the CREATE TABLE expenses statement
    old_expenses_table = '''    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        amountR5 REAL DEFAULT 0,
        amountR2 REAL DEFAULT 0,
        amountR1 REAL DEFAULT 0,
        amount50c REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');'''
    
    new_expenses_table = '''    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        notes REAL NOT NULL,
        coins REAL NOT NULL,
        amount REAL NOT NULL,
        amountR5 REAL DEFAULT 0,
        amountR2 REAL DEFAULT 0,
        amountR1 REAL DEFAULT 0,
        amount50c REAL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');'''
    
    content = content.replace(old_expenses_table, new_expenses_table)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Expenses table updated with notes and coins fields!")

if __name__ == '__main__':
    update_database_helper()
