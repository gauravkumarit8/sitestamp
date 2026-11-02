import 'saved_photo.dart';
import 'stamp_data.dart';

/// A stamped photo kept inside the app (separate from the gallery copy).
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.path,
    required this.data,
    this.sha256 = '',
  });

  final String id;
  final String path;
  final StampData data;

  /// SHA-256 of the saved JPEG, recorded at capture time.
  final String sha256;

  SavedPhoto toSavedPhoto() => SavedPhoto(path: path, data: data);
}
