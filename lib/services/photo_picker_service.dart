import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:a_one_bakeries_app/theme/app_theme.dart';

/// Photo Picker Service
/// 
/// Handles selecting photos from camera or gallery,
/// saving them to app directory, and managing photo files.

class PhotoPickerService {
  final ImagePicker _picker = ImagePicker();

  /// Show dialog to choose between camera or gallery
  Future<String?> pickEmployeePhoto(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBrown),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBrown),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return null;

    return await _pickAndSavePhoto(source);
  }

  /// Pick photo from source and save to app directory
  Future<String?> _pickAndSavePhoto(ImageSource source) async {
    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final employeePhotosDir = Directory('${appDir.path}/employee_photos');
      
      // Create directory if doesn't exist
      if (!await employeePhotosDir.exists()) {
        await employeePhotosDir.create(recursive: true);
      }

      // Generate unique filename
      final fileName = 'employee_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final savedPath = '${employeePhotosDir.path}/$fileName';

      // Copy file to app directory
      final File imageFile = File(image.path);
      await imageFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error picking/saving photo: $e');
      return null;
    }
  }

  /// Delete photo file
  Future<bool> deletePhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return false;

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Update photo (delete old, save new)
  Future<String?> updateEmployeePhoto(
    BuildContext context,
    String? oldPhotoPath,
  ) async {
    // Delete old photo if exists
    if (oldPhotoPath != null && oldPhotoPath.isNotEmpty) {
      await deletePhoto(oldPhotoPath);
    }

    // Pick and save new photo
    return await pickEmployeePhoto(context);
  }

  /// Show options to update or remove photo
  Future<String?> showPhotoOptions(
    BuildContext context,
    String? currentPhotoPath,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Employee Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentPhotoPath != null && currentPhotoPath.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.visibility, color: AppTheme.primaryBrown),
                title: const Text('View Photo'),
                onTap: () => Navigator.pop(context, 'view'),
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryBrown),
              title: Text(currentPhotoPath == null || currentPhotoPath.isEmpty
                  ? 'Add Photo'
                  : 'Change Photo'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            if (currentPhotoPath != null && currentPhotoPath.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorRed),
                title: const Text('Remove Photo'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == null) return null;

    switch (action) {
      case 'view':
        if (currentPhotoPath != null) {
          await _showPhotoViewer(context, currentPhotoPath);
        }
        return null;
      
      case 'change':
        return await updateEmployeePhoto(context, currentPhotoPath);
      
      case 'remove':
        await deletePhoto(currentPhotoPath);
        return ''; // Empty string means remove photo
      
      default:
        return null;
    }
  }

  /// Show full-screen photo viewer
  Future<void> _showPhotoViewer(BuildContext context, String photoPath) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}