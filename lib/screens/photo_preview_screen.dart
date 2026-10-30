import 'dart:io';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_photo.dart';

class PhotoPreviewScreen extends StatelessWidget {
  const PhotoPreviewScreen({super.key, required this.photo, this.onAllPhotos});

  final SavedPhoto photo;

  /// When set, an "All photos" action opens the in-app photo list.
  final VoidCallback? onAllPhotos;

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: photo.shareText,
          subject: 'SiteStamp photo',
          files: [XFile(photo.path, mimeType: 'image/jpeg')],
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the share sheet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
        actions: [
          if (onAllPhotos != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onAllPhotos!();
              },
              icon: const Icon(Icons.grid_view, color: Colors.white),
              label: const Text(
                'All photos',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(photo.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'This preview is no longer available. '
                      'The photo is still in your gallery.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
