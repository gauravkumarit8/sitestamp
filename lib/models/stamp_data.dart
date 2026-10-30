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
    this.address,
    this.branding = false,
    this.project = '',
  });

  final DateTime time;
  final String memo;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final bool isMocked;
  final String? address;
  final bool branding;
  final String project;

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

  /// Gallery album for a project; empty project -> the default album.
  static String albumFor(String project) {
    final cleaned = project
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'SiteStamp';
    final clipped =
        cleaned.length > 40 ? cleaned.substring(0, 40).trim() : cleaned;
    return 'SiteStamp - $clipped';
  }

  /// File name used in the gallery, e.g. SiteStamp_20261028_143205.jpg
  String get fileName {
    final t = time;
    return 'SiteStamp_${t.year}${_two(t.month)}${_two(t.day)}_'
        '${_two(t.hour)}${_two(t.minute)}${_two(t.second)}.jpg';
  }

  /// "UTC+05:30"
  static String tzLabel(DateTime t) {
    final off = t.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final a = off.abs();
    return 'UTC$sign${_two(a.inHours)}:${_two(a.inMinutes % 60)}';
  }

  /// "2026-10-28 14:32:05" (local time)
  static String isoLocal(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)} '
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  Map<String, Object?> toJson() => {
        'time': time.millisecondsSinceEpoch,
        'memo': memo,
        'lat': latitude,
        'lon': longitude,
        'alt': altitude,
        'acc': accuracy,
        'mock': isMocked,
        'address': address,
        'branding': branding,
        'project': project,
      };

  factory StampData.fromJson(Map<String, dynamic> j) => StampData(
        time: DateTime.fromMillisecondsSinceEpoch((j['time'] as num).toInt()),
        memo: (j['memo'] as String?) ?? '',
        latitude: (j['lat'] as num?)?.toDouble(),
        longitude: (j['lon'] as num?)?.toDouble(),
        altitude: (j['alt'] as num?)?.toDouble(),
        accuracy: (j['acc'] as num?)?.toDouble(),
        isMocked: (j['mock'] as bool?) ?? false,
        address: j['address'] as String?,
        branding: (j['branding'] as bool?) ?? false,
        project: (j['project'] as String?) ?? '',
      );

  List<String> toLines() {
    final lines = <String>[formatTime(time)];
    final proj = project.trim();
    if (proj.isNotEmpty) lines.add('Project: $proj');
    if (hasFix) {
      final addr = address?.trim();
      if (addr != null && addr.isNotEmpty) lines.add(addr);
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
    if (branding) lines.add('Made with SiteStamp');
    return lines;
  }
}
