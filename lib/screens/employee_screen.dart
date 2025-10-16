import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';
import 'package:a_one_bakeries_app/models/employee_model.dart';
import 'package:a_one_bakeries_app/database/database_helper.dart';
import 'package:a_one_bakeries_app/screens/employee_details_screen.dart';
import 'package:a_one_bakeries_app/widgets/add_edit_employee_dialog.dart';
import 'package:intl/intl.dart';

/// Employee Screen
/// 
/// Main screen for employee management.
/// Displays all employees with their roles and basic info.
/// Allows adding, editing, deleting, and viewing employee details.

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'ALL';

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all employees from database
  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _dbHelper.getAllEmployees();
      setState(() {
        _employees = employees;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading employees: $e');
      }
    }
  }

  /// Apply search and role filters
  void _applyFilters() {
    List<Employee> filtered = _employees;

    // Filter by role
    if (_selectedRole != 'ALL') {
      filtered = filtered.where((e) => e.role == _selectedRole).toList();
    }

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.firstName.toLowerCase().contains(query) ||
              e.lastName.toLowerCase().contains(query) ||
              e.idNumber.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredEmployees = filtered;
    });
  }

  /// Show add employee dialog
  Future<void> _showAddEmployeeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEditEmployeeDialog(),
    );

    if (result == true) {
      _loadEmployees();
      if (mounted) {
        _showSuccessSnackBar('Employee registered successfully!');
      }
    }
  }

  /// Show edit employee dialog
  Future<void> _showEditEmployeeDialog(Employee employee) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditEmployeeDialog(employee: employee),
    );

    if (result == true) {
      _loadEmployees();
      if (mounted) {
        _showSuccessSnackBar('Employee updated successfully!');
      }
    }
  }

  /// Delete employee
  Future<void> _deleteEmployee(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
            'Are you sure you want to delete ${employee.fullName}? This will also delete all related records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteEmployee(employee.id!);
        _loadEmployees();
        if (mounted) {
          _showSuccessSnackBar('Employee deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting employee: $e');
        }
      }
    }
  }

  /// Navigate to employee details
  void _navigateToEmployeeDetails(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsScreen(employee: employee),
      ),
    ).then((_) => _loadEmployees()); // Refresh on return
  }

  /// Get role icon
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Baker':
        return Icons.bakery_dining;
      case 'Driver':
        return Icons.local_shipping;
      case 'General Worker':
        return Icons.construction;
      case 'Supervisor':
        return Icons.supervisor_account;
      case 'Manager':
        return Icons.business_center;
      default:
        return Icons.person;
    }
  }

  /// Get role color
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Baker':
        return AppTheme.primaryBrown;
      case 'Driver':
        return AppTheme.secondaryOrange;
      case 'General Worker':
        return Colors.blue;
      case 'Supervisor':
        return Colors.purple;
      case 'Manager':
        return Colors.green;
      default:
        return AppTheme.darkBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Employees'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Role Filter Chips
          _buildRoleFilters(),

          // Employee Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredEmployees.length} ${_filteredEmployees.length == 1 ? 'Employee' : 'Employees'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Employees List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadEmployees,
                        color: AppTheme.primaryBrown,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            return _buildEmployeeCard(
                                _filteredEmployees[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// Build role filter chips
  Widget _buildRoleFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildRoleChip('ALL', 'All'),
          ...EmployeeRoles.allRoles.map((role) => _buildRoleChip(role, role)),
        ],
      ),
    );
  }

  /// Build single role filter chip
  Widget _buildRoleChip(String value, String label) {
    final isSelected = _selectedRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRole = value;
            _applyFilters();
          });
        },
        selectedColor: AppTheme.primaryBrown,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.darkBrown,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  /// Build employee card
  Widget _buildEmployeeCard(Employee employee) {
    final roleColor = _getRoleColor(employee.role);
    final roleIcon = _getRoleIcon(employee.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEmployeeDetails(employee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Employee Photo or Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: roleColor.withOpacity(0.1),
                child: employee.photoPath != null
                    ? ClipOval(
                        child: Image.network(
                          employee.photoPath!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: roleColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 30,
                        color: roleColor,
                      ),
              ),
              const SizedBox(width: 16),

              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      employee.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),

                    // Role with icon
                    Row(
                      children: [
                        Icon(
                          roleIcon,
                          size: 16,
                          color: roleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.role,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ID Number
                    Text(
                      '${employee.idType}: ${employee.idNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkBrown.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),

              // Actions Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditEmployeeDialog(employee);
                  } else if (value == 'delete') {
                    _deleteEmployee(employee);
                  } else if (value == 'details') {
                    _navigateToEmployeeDetails(employee);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 20),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
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
                        Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppTheme.errorRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.darkBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty && _selectedRole == 'ALL'
                ? 'No employees yet'
                : 'No employees found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty && _selectedRole == 'ALL'
                ? 'Tap + to register your first employee'
                : 'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkBrown.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}