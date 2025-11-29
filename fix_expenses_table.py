#!/usr/bin/env python3
"""Add notes and coins to expenses table - SIMPLE VERSION"""

file_path = 'lib/database/database_helper.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the expenses table and add notes/coins fields
new_lines = []
in_expenses_table = False
added_fields = False

for i, line in enumerate(lines):
    new_lines.append(line)
    
    # Detect start of expenses table
    if 'CREATE TABLE expenses(' in line:
        in_expenses_table = True
    
    # Add fields after description line
    if in_expenses_table and 'description TEXT NOT NULL,' in line and not added_fields:
        new_lines.append('        notes REAL NOT NULL,\r\n')
        new_lines.append('        coins REAL NOT NULL,\r\n')
        added_fields = True
        in_expenses_table = False

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✅ Added notes and coins to expenses table!")
