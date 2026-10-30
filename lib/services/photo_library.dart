import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/library_item.dart';
import '../models/stamp_data.dart';

/// App-private copy of every stamped photo (JPEG + a small JSON sidecar).
/// Removing a photo here never touches the copy in the phone's gallery.
class PhotoLibrary extends ChangeNotifier {
  PhotoLibrary({Directory? directory}) : _dir = directory;

  Directory? _dir;

  Future<Directory> _directory() async {
    final existing = _dir;
    if (existing != null) {
      if (!await existing.exists()) await existing.create(recursive: true);
      return existing;
    }
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/library');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    return d;
  }

  Future<LibraryItem?> add({
    required String sourcePath,
    required StampData data,
    int? maxCount,
  }) async {
    try {
      final dir = await _directory();
      final id =
          '${data.time.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
      final imgPath = '${dir.path}/$id.jpg';
      await File(sourcePath).copy(imgPath);
      await File('${dir.path}/$id.json')
          .writeAsString(jsonEncode(data.toJson()), flush: true);
      if (maxCount != null) await prune(maxCount, notify: false);
      notifyListeners();
      return LibraryItem(id: id, path: imgPath, data: data);
    } catch (_) {
      return null; // the gallery copy already exists; library is a bonus
    }
  }

  /// Newest first.
  Future<List<LibraryItem>> list() async {
    final dir = await _directory();
    final items = <LibraryItem>[];
    await for (final e in dir.list()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      try {
        final base = e.path.substring(0, e.path.length - 5);
        final img = File('$base.jpg');
        if (!await img.exists()) {
          await e.delete();
          continue;
        }
        final json = jsonDecode(await e.readAsString()) as Map<String, dynamic>;
        items.add(
          LibraryItem(
            id: base.substring(base.lastIndexOf('/') + 1),
            path: img.path,
            data: StampData.fromJson(json),
          ),
        );
      } catch (_) {
        // skip unreadable entries
      }
    }
    items.sort((a, b) {
      final c = b.data.time.compareTo(a.data.time);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return items;
  }

  Future<void> deleteAll(List<LibraryItem> items, {bool notify = true}) async {
    for (final it in items) {
      try {
        final f = File(it.path);
        if (await f.exists()) await f.delete();
        final j = File(it.path.replaceAll(RegExp(r'\.jpg$'), '.json'));
        if (await j.exists()) await j.delete();
      } catch (_) {}
    }
    if (notify) notifyListeners();
  }

  /// Keeps only the newest [maxCount] photos.
  Future<void> prune(int maxCount, {bool notify = true}) async {
    final all = await list();
    if (all.length <= maxCount) return;
    await deleteAll(all.sublist(maxCount), notify: false);
    if (notify) notifyListeners();
  }
}
