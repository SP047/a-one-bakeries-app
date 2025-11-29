#!/usr/bin/env python3
"""Make notes field optional in expense dialog"""

file_path = 'lib/widgets/add_expense_dialog.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Change label from required to optional
content = content.replace(
    "labelText: 'Notes (Paper Money)',",
    "labelText: 'Notes (Paper Money) - Optional',"
)

# Change validation to allow empty
old_validation = '''                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter notes amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },'''

new_validation = '''                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount < 0) {
                      return 'Please enter valid amount';
                    }
                  }
                  // Check if at least notes or coins has a value
                  final notes = double.tryParse(value?.trim() ?? '0') ?? 0.0;
                  final coins = _calculateCoins();
                  if (notes == 0 && coins == 0) {
                    return 'Enter notes or coins';
                  }
                  return null;
                },'''

content = content.replace(old_validation, new_validation)

# Change notes parsing to default to 0
content = content.replace(
    'notes: double.parse(_notesController.text.trim()),',
    'notes: double.tryParse(_notesController.text.trim()) ?? 0.0,'
)

# Change total preview condition
content = content.replace(
    '''              // Total Preview
              if (_notesController.text.isNotEmpty &&
                  double.tryParse(_notesController.text) != null)''',
    '''              // Total Preview
              if (total > 0)'''
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Made notes field optional in expense dialog!")
