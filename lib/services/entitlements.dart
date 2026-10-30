import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single place that decides what is free and what is Pro.
/// Tune the getters below to change the free/Pro split.
///
/// Pro comes from a Google Play purchase (see BillingService). The purchase is
/// cached so the app works offline; it must be re-confirmed by Play within
/// [_grace] or the app falls back to the free plan.
/// Debug builds also get a "Pro (testing only)" switch.
class Entitlements extends ChangeNotifier {
  Entitlements._(this._prefs);

  static const String _kDebugPro = 'debug_pro';
  static const String _kPurchasedPro = 'purchased_pro';
  static const String _kConfirmedAt = 'purchased_pro_confirmed_ms';
  static const Duration _grace = Duration(days: 14);

  final SharedPreferences _prefs;
  bool _debugPro = false;
  bool _purchasedPro = false;

  bool get isPro => _debugPro || _purchasedPro;
  bool get isPurchasedPro => _purchasedPro;

  // ---- The free / Pro split ----
  /// Street address on the stamp.
  bool get canShowAddress => isPro;

  /// Small "Made with SiteStamp" line on free photos.
  bool get showBranding => !isPro;

  /// How many recent notes appear as chips (more are stored for upgrades).
  int get maxRecentMemos => isPro ? 10 : 3;

  static Future<Entitlements> load() async {
    final e = Entitlements._(await SharedPreferences.getInstance());
    if (kDebugMode) e._debugPro = e._prefs.getBool(_kDebugPro) ?? false;
    final flag = e._prefs.getBool(_kPurchasedPro) ?? false;
    final at = e._prefs.getInt(_kConfirmedAt) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - at;
    e._purchasedPro = flag && age < _grace.inMilliseconds;
    return e;
  }

  /// Testing only; ignored outside debug builds.
  Future<void> setDebugPro(bool value) async {
    if (!kDebugMode) return;
    _debugPro = value;
    notifyListeners();
    await _prefs.setBool(_kDebugPro, value);
  }

  /// Called by the billing layer when Play confirms (or no longer confirms) Pro.
  Future<void> applyPurchase({required bool pro}) async {
    _purchasedPro = pro;
    notifyListeners();
    await _prefs.setBool(_kPurchasedPro, pro);
    if (pro) {
      await _prefs.setInt(
        _kConfirmedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }
}
