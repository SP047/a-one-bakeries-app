#!/usr/bin/env python3
"""Add _navigateToSettings method to dashboard"""

file_path = 'lib/screens/dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the line after _navigateToNotifications method closes
insert_index = None
for i, line in enumerate(lines):
    if '/// Navigate to Notifications Screen' in line:
        # Find the closing brace of this method
        for j in range(i, min(i + 15, len(lines))):
            if lines[j].strip() == '}' and j > i + 5:
                insert_index = j + 1
                break
        break

if insert_index:
    new_method = '''
  /// Navigate to Settings Screen
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
'''
    lines.insert(insert_index, new_method)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print("✅ Added _navigateToSettings method!")
else:
    print("❌ Could not find insertion point")
