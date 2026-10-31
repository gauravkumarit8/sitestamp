import 'stamp_data.dart';

/// A stamped photo that was just saved; used by the preview and share screen.
class SavedPhoto {
  const SavedPhoto({required this.path, required this.data});

  /// Copy of the stamped JPEG kept in the app cache for sharing.
  final String path;
  final StampData data;

  /// Text sent along with the picture (WhatsApp shows it as the caption).
  String get shareText {
    final d = data;
    final lines = <String>[];
    if (d.company.trim().isNotEmpty) lines.add(d.company.trim());
    lines.add(StampData.formatTime(d.time));
    final proj = d.project.trim();
    if (proj.isNotEmpty) lines.add('Project: $proj');
    final refLine = [
      if (d.reference.trim().isNotEmpty) 'Ref: ${d.reference.trim()}',
      if (d.inspector.trim().isNotEmpty) 'By: ${d.inspector.trim()}',
    ].join('   ');
    if (refLine.isNotEmpty) lines.add(refLine);
    final addr = d.address?.trim();
    if (addr != null && addr.isNotEmpty) lines.add(addr);
    if (d.hasFix) {
      final lat = d.latitude!.toStringAsFixed(6);
      final lon = d.longitude!.toStringAsFixed(6);
      lines.add('Lat $lat, Lon $lon');
      lines.add('https://maps.google.com/?q=$lat,$lon');
    }
    if (d.memo.isNotEmpty) lines.add('Note: ${d.memo}');
    return lines.join('\n');
  }
}
