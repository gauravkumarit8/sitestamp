import 'saved_photo.dart';
import 'stamp_data.dart';

/// A stamped photo kept inside the app (separate from the gallery copy).
class LibraryItem {
  const LibraryItem({required this.id, required this.path, required this.data});

  final String id;
  final String path;
  final StampData data;

  SavedPhoto toSavedPhoto() => SavedPhoto(path: path, data: data);
}
