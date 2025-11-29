# Script to add KM/service display to vehicle cards

with open('lib/screens/vehicle_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the section after disk expiry display and before actions menu
# Add KM and service status display

old_card_section = '''                      ],
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>('''

new_card_section = '''                      ],
                      // KM and Service Status
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 14,
                            color: AppTheme.darkBrown.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'KM: ${vehicle.currentKm}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            vehicle.serviceStatus.icon,
                            size: 14,
                            color: vehicle.serviceStatus.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.isServiceDue 
                                ? 'Service Due!'
                                : '${vehicle.kmUntilService} km to service',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: vehicle.serviceStatus.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>('''

content = content.replace(old_card_section, new_card_section)

# Also add Record KM and Record Service to the popup menu
old_popup_menu = '''                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],'''

new_popup_menu = '''                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'record_km',
                      child: Row(
                        children: [
                          Icon(Icons.speed, size: 20),
                          SizedBox(width: 8),
                          Text('Record KM'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'record_service',
                      child: Row(
                        children: [
                          Icon(Icons.build, size: 20),
                          SizedBox(width: 8),
                          Text('Record Service'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],'''

content = content.replace(old_popup_menu, new_popup_menu)

# Update the onSelected to handle new menu items
old_onselected = '''                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditVehicleDialog(vehicle);
                    } else if (value == 'delete') {
                      _deleteVehicle(vehicle);
                    }
                  },'''

new_onselected = '''                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditVehicleDialog(vehicle);
                    } else if (value == 'record_km') {
                      _showKmRecordDialog(vehicle);
                    } else if (value == 'record_service') {
                      _showServiceRecordDialog(vehicle);
                    } else if (value == 'delete') {
                      _deleteVehicle(vehicle);
                    }
                  },'''

content = content.replace(old_onselected, new_onselected)

with open('lib/screens/vehicle_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Vehicle cards updated!")
print("   - Added KM display (current KM)")
print("   - Added service status (KM until service)")
print("   - Added Record KM/Service to card menu")
print("\n🎉 Vehicle screen KM integration COMPLETE!")
