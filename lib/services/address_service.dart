import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Reverse-geocodes in the background so the address is already cached when
/// the shutter is tapped. Never blocks capture; if no address is available
/// the photo is simply stamped without one.
class AddressService {
  static const double _refreshMeters = 50;
  static const double _maxUseMeters = 150;
  static const Duration _retryGap = Duration(seconds: 20);

  double? _lat;
  double? _lon;
  String? _address;
  bool _busy = false;
  bool _disposed = false;
  DateTime? _lastAttempt;

  /// Joins non-empty, de-duplicated parts: "MG Road, Pune, Maharashtra".
  static String joinParts(Iterable<String?> parts) {
    final out = <String>[];
    for (final part in parts) {
      final t = part?.trim();
      if (t != null && t.isNotEmpty && !out.contains(t)) out.add(t);
    }
    return out.join(', ');
  }

  Future<void> update(Position p) async {
    if (_busy || _disposed || p.accuracy > 100) return;

    final lat = _lat;
    final lon = _lon;
    if (_address != null && lat != null && lon != null) {
      final moved = Geolocator.distanceBetween(lat, lon, p.latitude, p.longitude);
      if (moved < _refreshMeters) return;
    }

    final last = _lastAttempt;
    if (last != null && DateTime.now().difference(last) < _retryGap) return;

    _busy = true;
    _lastAttempt = DateTime.now();
    try {
      final marks = await placemarkFromCoordinates(p.latitude, p.longitude)
          .timeout(const Duration(seconds: 8));
      if (_disposed || marks.isEmpty) return;
      final m = marks.first;
      final text = joinParts([
        m.street,
        m.subLocality,
        m.locality,
        m.administrativeArea,
        m.postalCode,
      ]);
      if (text.isNotEmpty) {
        _address = text;
        _lat = p.latitude;
        _lon = p.longitude;
      }
    } catch (_) {
      // No network / no geocoder on this device: stamp without an address.
    } finally {
      _busy = false;
    }
  }

  /// Cached address if it was resolved close to [p], otherwise null.
  String? addressFor(Position p) {
    final lat = _lat;
    final lon = _lon;
    if (_address == null || lat == null || lon == null) return null;
    final d = Geolocator.distanceBetween(lat, lon, p.latitude, p.longitude);
    return d <= _maxUseMeters ? _address : null;
  }

  void dispose() {
    _disposed = true;
  }
}
