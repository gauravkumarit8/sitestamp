import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/tx.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_photo.dart';

class PhotoPreviewScreen extends StatelessWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.photo,
    this.onAllPhotos,
    this.onAnnotate,
    this.annotateLocked = false,
  });

  final SavedPhoto photo;

  /// When set, an "All photos" action opens the in-app photo list.
  final VoidCallback? onAllPhotos;

  /// When set, an "Annotate" button opens the drawing screen for this photo.
  final void Function(SavedPhoto photo)? onAnnotate;
  final bool annotateLocked;

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
        const SnackBar(content: Tx('Could not open the share sheet.')),
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
        title: const Tx('Photo'),
        actions: [
          if (onAllPhotos != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onAllPhotos!();
              },
              icon: const Icon(Icons.grid_view, color: Colors.white),
              label: const Tx(
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
                    child: Tx(
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
              child: Row(
                children: [
                  if (onAnnotate != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onAnnotate!(photo),
                        icon: Icon(annotateLocked ? Icons.lock_outline : Icons.draw_outlined),
                        label: const Tx('Annotate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _share(context),
                      icon: const Icon(Icons.share),
                      label: const Tx('Share'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
