import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small persisted settings: address toggle and recent memos.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const String _kShowAddress = 'show_address';
  static const String _kShowGrid = 'show_grid';
  static const String _kRecentMemos = 'recent_memos';
  static const int maxRecent = 10;

  /// Shown when the user has no recent memos yet.
  static const List<String> defaultPresets = [
    'Before',
    'After',
    'Site visit',
    'Issue found',
  ];

  final SharedPreferences _prefs;
  bool _showAddress = true;
  bool _showGrid = false;
  List<String> _recent = <String>[];

  bool get showAddress => _showAddress;
  bool get showGrid => _showGrid;
  List<String> get recentMemos => List.unmodifiable(_recent);

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppSettings._(prefs);
    s._showAddress = prefs.getBool(_kShowAddress) ?? true;
    s._showGrid = prefs.getBool(_kShowGrid) ?? false;
    s._recent = prefs.getStringList(_kRecentMemos) ?? <String>[];
    return s;
  }

  Future<void> setShowAddress(bool value) async {
    _showAddress = value;
    notifyListeners();
    await _prefs.setBool(_kShowAddress, value);
  }

  Future<void> setShowGrid(bool value) async {
    _showGrid = value;
    notifyListeners();
    await _prefs.setBool(_kShowGrid, value);
  }

  Future<void> addRecentMemo(String memo) async {
    final m = memo.trim();
    if (m.isEmpty) return;
    _recent = [m, ..._recent.where((e) => e != m)].take(maxRecent).toList();
    notifyListeners();
    await _prefs.setStringList(_kRecentMemos, _recent);
  }

  Future<void> removeRecentMemo(String memo) async {
    _recent = _recent.where((e) => e != memo).toList();
    notifyListeners();
    await _prefs.setStringList(_kRecentMemos, _recent);
  }
}
