import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';

import 'hindi.dart';

/// Current interface language ('en' or 'hi'). Screens listen to it so the whole
/// app switches immediately.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final AppLanguage instance = AppLanguage._();

  String _code = 'en';
  String get code => _code;
  bool get isHindi => _code == 'hi';

  void set(String code) {
    final next = code == 'hi' ? 'hi' : 'en';
    if (next == _code) return;
    _code = next;
    notifyListeners();
  }

  /// First launch: follow the phone's language if it is Hindi.
  static String detect() {
    try {
      return PlatformDispatcher.instance.locale.languageCode == 'hi' ? 'hi' : 'en';
    } catch (_) {
      return 'en';
    }
  }
}

/// Translates an English UI string. Unknown strings stay in English, so adding
/// a new screen never breaks anything; add the Hindi to hindi.dart when ready.
String tr(String english) {
  if (!AppLanguage.instance.isHindi) return english;
  return kHindi[english] ?? english;
}
