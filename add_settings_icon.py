#!/usr/bin/env python3
"""Add settings icon to dashboard appBar"""

file_path = 'lib/screens/dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the actions closing
old_text = '''                ),
            ],
          ),
        ],
      ),'''

new_text = '''                ),
            ],
          ),
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),'''

if old_text in content:
    content = content.replace(old_text, new_text)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ Added settings icon to dashboard!")
else:
    print("❌ Could not find target location")
