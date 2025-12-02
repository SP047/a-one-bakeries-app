#!/usr/bin/env python3
"""Fix database path to use writable directory"""

file_path = 'lib/database/database_helper.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the database path logic
old_text = '''    // Get the database file path
    String path = join(await getDatabasesPath(), 'a_one_bakeries.db');'''

new_text = '''    // CRITICAL FIX: Use getApplicationDocumentsDirectory() for writable location
    // This ensures database is writable in both debug and release builds
    final directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'a_one_bakeries.db');'''

if old_text in content:
    content = content.replace(old_text, new_text)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ Fixed database path to use writable directory!")
else:
    print("❌ Could not find target location")
    print("Looking for:", old_text[:50])
