#!/usr/bin/env python3
"""Add notes and coins fields to expenses table"""

file_path = 'lib/database/database_helper.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the expenses table and add notes/coins fields
old_line = '        amount REAL NOT NULL,'
new_lines = '''        notes REAL NOT NULL,
        coins REAL NOT NULL,
        amount REAL NOT NULL,'''

content = content.replace(old_line, new_lines, 1)  # Only replace first occurrence in expenses table

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Added notes and coins fields to expenses table!")
