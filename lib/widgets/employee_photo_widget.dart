import 'dart:io';
import 'package:flutter/material.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';

/// Employee Photo Widget
/// 
/// Displays employee photo or default avatar icon.
/// Handles both file paths and shows default icon if no photo.

class EmployeePhotoWidget extends StatelessWidget {
  final String? photoPath;
  final double radius;
  final Color? backgroundColor;
  final IconData? defaultIcon;

  const EmployeePhotoWidget({
    super.key,
    this.photoPath,
    this.radius = 30,
    this.backgroundColor,
    this.defaultIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.primaryBrown.withOpacity(0.1);
    final icon = defaultIcon ?? Icons.person;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: _buildPhotoContent(icon),
    );
  }

  Widget _buildPhotoContent(IconData icon) {
    // No photo - show default icon
    if (photoPath == null || photoPath!.isEmpty) {
      return Icon(
        icon,
        size: radius * 1.2,
        color: AppTheme.primaryBrown,
      );
    }

    // Check if it's a file path
    final file = File(photoPath!);
    
    return ClipOval(
      child: file.existsSync()
          ? Image.file(
              file,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // If file doesn't exist or error loading, show default icon
                return Icon(
                  icon,
                  size: radius * 1.2,
                  color: AppTheme.primaryBrown,
                );
              },
            )
          : Icon(
              icon,
              size: radius * 1.2,
              color: AppTheme.primaryBrown,
            ),
    );
  }
}

/// Employee Photo Picker Widget
/// 
/// Interactive widget that allows picking/changing employee photo.
/// Shows current photo with edit overlay on tap.

class EmployeePhotoPicker extends StatelessWidget {
  final String? photoPath;
  final double radius;
  final VoidCallback onTap;
  final bool showEditIcon;

  const EmployeePhotoPicker({
    super.key,
    this.photoPath,
    this.radius = 50,
    required this.onTap,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Photo or default avatar
          EmployeePhotoWidget(
            photoPath: photoPath,
            radius: radius,
          ),

          // Edit icon overlay
          if (showEditIcon)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  photoPath == null || photoPath!.isEmpty
                      ? Icons.add_a_photo
                      : Icons.edit,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}