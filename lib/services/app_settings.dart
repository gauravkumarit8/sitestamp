import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stamp_style.dart';

/// Small persisted settings: address toggle and recent memos.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const String _kShowAddress = 'show_address';
  static const String _kShowGrid = 'show_grid';
  static const String _kRecentMemos = 'recent_memos';
  static const String _kProjects = 'projects';
  static const String _kProject = 'current_project';
  static const String _kStampPos = 'stamp_position';
  static const String _kStampSize = 'stamp_size';
  static const int maxProjects = 30;
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
  List<String> _projects = <String>[];
  String _project = '';
  StampStyle _style = const StampStyle();

  bool get showAddress => _showAddress;
  bool get showGrid => _showGrid;
  List<String> get recentMemos => List.unmodifiable(_recent);
  List<String> get projects => List.unmodifiable(_projects);
  String get project => _project;
  StampStyle get stampStyle => _style;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppSettings._(prefs);
    s._showAddress = prefs.getBool(_kShowAddress) ?? true;
    s._showGrid = prefs.getBool(_kShowGrid) ?? false;
    s._recent = prefs.getStringList(_kRecentMemos) ?? <String>[];
    s._projects = prefs.getStringList(_kProjects) ?? <String>[];
    s._project = prefs.getString(_kProject) ?? '';
    final pos = (prefs.getInt(_kStampPos) ?? 0)
        .clamp(0, StampPosition.values.length - 1)
        .toInt();
    final size = (prefs.getInt(_kStampSize) ?? 1)
        .clamp(0, StampSize.values.length - 1)
        .toInt();
    s._style = StampStyle(
      position: StampPosition.values[pos],
      size: StampSize.values[size],
    );
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

  Future<void> addProject(String name) async {
    var n = name.trim();
    if (n.isEmpty) return;
    if (n.length > 30) n = n.substring(0, 30).trim();
    if (!_projects.contains(n) && _projects.length < maxProjects) {
      _projects = [..._projects, n];
    }
    _project = n;
    notifyListeners();
    await _prefs.setStringList(_kProjects, _projects);
    await _prefs.setString(_kProject, _project);
  }

  /// Pass '' for the default album.
  Future<void> selectProject(String name) async {
    _project = name;
    notifyListeners();
    await _prefs.setString(_kProject, _project);
  }

  Future<void> removeProject(String name) async {
    _projects = _projects.where((e) => e != name).toList();
    if (_project == name) _project = '';
    notifyListeners();
    await _prefs.setStringList(_kProjects, _projects);
    await _prefs.setString(_kProject, _project);
  }

  Future<void> setStampPosition(StampPosition p) async {
    _style = _style.copyWith(position: p);
    notifyListeners();
    await _prefs.setInt(_kStampPos, p.index);
  }

  Future<void> setStampSize(StampSize s) async {
    _style = _style.copyWith(size: s);
    notifyListeners();
    await _prefs.setInt(_kStampSize, s.index);
  }

  Future<void> removeRecentMemo(String memo) async {
    _recent = _recent.where((e) => e != memo).toList();
    notifyListeners();
    await _prefs.setStringList(_kRecentMemos, _recent);
  }
}
