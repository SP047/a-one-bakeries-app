# Remove duplicate KM methods from database_helper.dart

with open('lib/database/database_helper.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the first occurrence of KM tracking section
first_km_section = -1
for i, line in enumerate(lines):
    if 'KM TRACKING OPERATIONS' in line:
        first_km_section = i
        break

if first_km_section == -1:
    print("❌ Could not find KM tracking section")
    exit(1)

# Find where the first KM section ends (look for the closing brace of the class)
# The KM methods should end before any duplicate section starts
# Look for the second occurrence of "KM TRACKING OPERATIONS"
second_km_section = -1
for i in range(first_km_section + 1, len(lines)):
    if 'KM TRACKING OPERATIONS' in line or 'Future<int> addKmRecord' in lines[i]:
        second_km_section = i
        break

if second_km_section == -1:
    print("✅ No duplicates found")
    exit(0)

# Keep everything up to the second KM section, then add closing brace
output_lines = lines[:second_km_section]

# Make sure we have the closing brace for the class
if not output_lines[-1].strip() == '}':
    output_lines.append('}\n')

with open('lib/database/database_helper.dart', 'w', encoding='utf-8') as f:
    f.writelines(output_lines)

print(f"✅ Removed duplicate KM methods starting at line {second_km_section + 1}")
print(f"   File reduced from {len(lines)} to {len(output_lines)} lines")
