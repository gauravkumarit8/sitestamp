import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single place that decides what is free and what is Pro.
/// Tune the getters below to change the free/Pro split.
///
/// Billing is not connected yet. In debug builds (the CI APK) Pro can be
/// toggled from the settings sheet so both modes can be tested on a phone.
/// Release builds stay on the free plan until billing is added.
class Entitlements extends ChangeNotifier {
  Entitlements._(this._prefs);

  static const String _kDebugPro = 'debug_pro';

  final SharedPreferences _prefs;
  bool _isPro = false;

  bool get isPro => _isPro;

  // ---- The free / Pro split ----
  /// Street address on the stamp.
  bool get canShowAddress => _isPro;

  /// Small "Made with SiteStamp" line on free photos.
  bool get showBranding => !_isPro;

  /// How many recent notes appear as chips (more are stored for upgrades).
  int get maxRecentMemos => _isPro ? 10 : 3;

  static Future<Entitlements> load() async {
    final e = Entitlements._(await SharedPreferences.getInstance());
    if (kDebugMode) e._isPro = e._prefs.getBool(_kDebugPro) ?? false;
    return e;
  }

  /// Testing only; ignored outside debug builds.
  Future<void> setDebugPro(bool value) async {
    if (!kDebugMode) return;
    _isPro = value;
    notifyListeners();
    await _prefs.setBool(_kDebugPro, value);
  }

  /// Called by the billing layer once it exists.
  void applyPurchase({required bool pro}) {
    _isPro = pro;
    notifyListeners();
  }
}
