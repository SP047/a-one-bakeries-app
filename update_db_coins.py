# Update database schema for coin denomination breakdown

import re

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update version to 7
content = re.sub(r'version: \d+,', 'version: 7,', content)

# 2. Add coin fields to income table
# Find the income table and add fields before createdAt
income_pattern = r'(CREATE TABLE income\([^)]+notes REAL NOT NULL,\s+coins REAL NOT NULL,\s+total REAL NOT NULL,)\s+(createdAt TEXT NOT NULL)'
income_replacement = r'\1\n        amountR5 REAL DEFAULT 0,\n        amountR2 REAL DEFAULT 0,\n        amountR1 REAL DEFAULT 0,\n        amount50c REAL DEFAULT 0,\n        \2'
content = re.sub(income_pattern, income_replacement, content, flags=re.DOTALL)

# 3. Add coin fields to expenses table  
# Find the expenses table and add fields before createdAt
expenses_pattern = r'(CREATE TABLE expenses\([^)]+amount REAL NOT NULL,)\s+(createdAt TEXT NOT NULL)'
expenses_replacement = r'\1\n        amountR5 REAL DEFAULT 0,\n        amountR2 REAL DEFAULT 0,\n        amountR1 REAL DEFAULT 0,\n        amount50c REAL DEFAULT 0,\n        \2'
content = re.sub(expenses_pattern, expenses_replacement, content, flags=re.DOTALL)

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Database schema updated to v7!")
print("   - Version: 7")
print("   - Income table: Added coin denomination fields")
print("   - Expenses table: Added coin denomination fields")
