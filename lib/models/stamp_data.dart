/// Everything that gets printed on the photo. Pure Dart so it is unit-testable.
class StampData {
  const StampData({
    required this.time,
    required this.memo,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.isMocked = false,
  });

  final DateTime time;
  final String memo;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final bool isMocked;

  bool get hasFix => latitude != null && longitude != null;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String formatTime(DateTime t) {
    final off = t.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final a = off.abs();
    final tz = 'UTC$sign${_two(a.inHours)}:${_two(a.inMinutes % 60)}';
    return '${_two(t.day)} ${_months[t.month - 1]} ${t.year}  '
        '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}  $tz';
  }

  /// File name used in the gallery, e.g. SiteStamp_20261028_143205.jpg
  String get fileName {
    final t = time;
    return 'SiteStamp_${t.year}${_two(t.month)}${_two(t.day)}_'
        '${_two(t.hour)}${_two(t.minute)}${_two(t.second)}.jpg';
  }

  List<String> toLines() {
    final lines = <String>[formatTime(time)];
    if (hasFix) {
      lines.add(
        'Lat ${latitude!.toStringAsFixed(6)}  Lon ${longitude!.toStringAsFixed(6)}',
      );
      final parts = <String>[];
      if (altitude != null) parts.add('Alt ${altitude!.round()} m');
      if (accuracy != null) parts.add('Accuracy ±${accuracy!.round()} m');
      if (parts.isNotEmpty) lines.add(parts.join('   '));
      if (isMocked) lines.add('WARNING: mock location detected');
    } else {
      lines.add('GPS location unavailable');
    }
    if (memo.isNotEmpty) lines.add('Note: $memo');
    return lines;
  }
}
