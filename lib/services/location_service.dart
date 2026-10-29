import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/stamp_data.dart';

/// Keeps a live GPS stream open so a fix is ready before the shutter is tapped.
class LocationService {
  StreamSubscription<Position>? _sub;
  DateTime? _receivedAt;

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

  StampData snapshot({
    required DateTime time,
    required String memo,
    String? address,
    bool branding = false,
  }) {
    final p = freshFix();
    return StampData(
      time: time,
      memo: memo,
      latitude: p?.latitude,
      longitude: p?.longitude,
      altitude: p?.altitude,
      accuracy: p?.accuracy,
      isMocked: p?.isMocked ?? false,
      address: p == null ? null : address,
      branding: branding,
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    latest.dispose();
    serviceEnabled.dispose();
  }
}
