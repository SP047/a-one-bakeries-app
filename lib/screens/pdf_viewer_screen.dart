import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:a_one_bakeries_app/theme/app_theme.dart';

/// PDF Viewer Screen - Platform Aware
/// 
/// - Uses flutter_pdfview for Android/iOS
/// - Opens with default Windows app on desktop
/// - Handles all platforms gracefully

class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  String? _errorMessage;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _initializePDFViewer();
  }

  /// Initialize PDF viewer based on platform
  Future<void> _initializePDFViewer() async {
    // Check if file exists
    final file = File(widget.filePath);
    if (!await file.exists()) {
      setState(() {
        _errorMessage = 'File not found. It may have been moved or deleted.';
      });
      return;
    }

    // For Windows/Desktop: Open with default app immediately
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _openWithDefaultApp();
    } else {
      // For Android/iOS: Use flutter_pdfview
      setState(() {
        _isReady = true;
      });
    }
  }

  /// Open PDF with default system app (Windows/Mac/Linux)
  Future<void> _openWithDefaultApp() async {
    setState(() {
      _isOpening = true;
    });

    try {
      final Uri fileUri = Uri.file(widget.filePath);
      
      if (await canLaunchUrl(fileUri)) {
        final launched = await launchUrl(
          fileUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          // Successfully opened, wait a bit then close this screen
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _errorMessage = 'Could not open PDF with default application.';
            _isOpening = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No application found to open PDF files.';
          _isOpening = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error opening PDF: $e';
        _isOpening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Desktop platforms: Show opening screen
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _buildDesktopScreen();
    }

    // Mobile platforms: Show full PDF viewer
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (_isReady)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: _errorMessage != null
          ? _buildErrorState()
          : _buildMobilePDFViewer(),
      bottomNavigationBar: _isReady ? _buildPageNavigator() : null,
    );
  }

  /// Build desktop screen (Windows/Mac/Linux)
  Widget _buildDesktopScreen() {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isOpening) ...[
                // Opening PDF animation
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBrown),
                ),
                const SizedBox(height: 24),
                Text(
                  'Opening PDF...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The PDF will open in your default PDF viewer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_errorMessage != null) ...[
                // Error state
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppTheme.errorRed.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Unable to Open PDF',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkBrown.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _openWithDefaultApp,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Show file location
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Location:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.filePath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build mobile PDF viewer (Android/iOS)
  Widget _buildMobilePDFViewer() {
    return Stack(
      children: [
        PDFView(
          filePath: widget.filePath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: _currentPage,
          fitPolicy: FitPolicy.WIDTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = 'Error loading PDF: $error';
            });
          },
          onPageError: (page, error) {
            setState(() {
              _errorMessage = 'Error on page $page: $error';
            });
          },
          onPageChanged: (int? page, int? total) {
            setState(() {
              _currentPage = page ?? 0;
            });
          },
        ),
        
        // Loading indicator
        if (!_isReady && _errorMessage == null)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorRed.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load PDF',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build page navigator at bottom (mobile only)
  Widget _buildPageNavigator() {
    final canGoPrevious = _currentPage > 0;
    final canGoNext = _currentPage < _totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: canGoPrevious ? Colors.white : Colors.grey,
              onPressed: canGoPrevious
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              color: canGoNext ? Colors.white : Colors.grey,
              onPressed: canGoNext
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}