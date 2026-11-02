import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/stamp_data.dart';
import '../models/stamp_style.dart';

/// Keeps a live GPS stream open so a fix is ready before the shutter is tapped.
class LocationService {
  StreamSubscription<Position>? _sub;
  DateTime? _receivedAt;
  DateTime? _lastMockAt;

  final ValueNotifier<Position?> latest = ValueNotifier<Position?>(null);
  final ValueNotifier<bool> serviceEnabled = ValueNotifier<bool>(true);

  Future<void> start() async {
    if (_sub != null) return;
    serviceEnabled.value = await Geolocator.isLocationServiceEnabled();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(
      (p) {
        _receivedAt = DateTime.now();
        if (p.isMocked) _lastMockAt = _receivedAt;
        serviceEnabled.value = true;
        latest.value = p;
      },
      onError: (Object _) {
        serviceEnabled.value = false;
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  /// The latest fix, or null if none arrived within [maxAge].
  Position? freshFix({Duration maxAge = const Duration(seconds: 30)}) {
    final p = latest.value;
    final at = _receivedAt;
    if (p == null || at == null) return null;
    return DateTime.now().difference(at) <= maxAge ? p : null;
  }

  /// True if any fix in the last 10 minutes was flagged as mock/fake.
  bool get mockSeenRecently {
    final at = _lastMockAt;
    return at != null && DateTime.now().difference(at) < const Duration(minutes: 10);
  }

  /// True if the phone clock differs from the GPS fix time by over 5 minutes.
  bool get clockMismatch {
    final p = freshFix();
    if (p == null) return false;
    final DateTime? ts = p.timestamp;
    if (ts == null) return false;
    return DateTime.now().difference(ts).abs() > const Duration(minutes: 5);
  }

  StampData snapshot({
    required DateTime time,
    required String memo,
    String? address,
    bool branding = false,
    String project = '',
    StampLocationMode locationMode = StampLocationMode.both,
    String company = '',
    String reference = '',
    String inspector = '',
    String photoId = '',
    double? siteDistanceM,
    double? siteRadiusM,
    String step = '',
  }) {
    final p = freshFix();
    return StampData(
      time: time,
      memo: memo,
      latitude: p?.latitude,
      longitude: p?.longitude,
      altitude: p?.altitude,
      accuracy: p?.accuracy,
      isMocked: (p?.isMocked ?? false) || mockSeenRecently,
      clockMismatch: clockMismatch,
      photoId: photoId,
      siteDistanceM: siteDistanceM,
      siteRadiusM: siteRadiusM,
      step: step,
      address: p == null ? null : address,
      branding: branding,
      project: project,
      locationMode: locationMode,
      company: company,
      reference: reference,
      inspector: inspector,
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    latest.dispose();
    serviceEnabled.dispose();
  }
}
