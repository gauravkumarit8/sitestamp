import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/checklist.dart';
import '../models/site_location.dart';
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
  static const String _kLocationMode = 'location_mode';
  static const String _kSites = 'project_sites';
  static const String _kChecklists = 'checklists';
  static const String _kActiveChecklist = 'active_checklist';
  static const String _kProgress = 'checklist_progress';
  static const String _kStampTheme = 'stamp_theme';
  static const String _kCompany = 'stamp_company';
  static const String _kReference = 'stamp_reference';
  static const String _kInspector = 'stamp_inspector';
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
  StampLocationMode _locationMode = StampLocationMode.addressFirst;
  Map<String, SiteLocation> _sites = <String, SiteLocation>{};
  List<Checklist> _customChecklists = <Checklist>[];
  String _activeChecklistId = '';
  Map<String, List<int>> _progress = <String, List<int>>{};
  String _company = '';
  String _reference = '';
  String _inspector = '';

  bool get showAddress => _showAddress;
  bool get showGrid => _showGrid;
  List<String> get recentMemos => List.unmodifiable(_recent);
  List<String> get projects => List.unmodifiable(_projects);
  String get project => _project;
  StampStyle get stampStyle => _style;
  StampLocationMode get locationMode => _locationMode;
  String get companyName => _company;
  SiteLocation? siteFor(String project) => _sites[project];

  // ---- checklists ----
  List<Checklist> get checklists => [...Checklist.builtIns, ..._customChecklists];

  Checklist? get activeChecklist {
    for (final c in checklists) {
      if (c.id == _activeChecklistId) return c;
    }
    return null;
  }

  String _progressKey(String project) => '$project|$_activeChecklistId';

  Set<int> completedSteps(String project) =>
      (_progress[_progressKey(project)] ?? const <int>[]).toSet();

  /// First step not done yet for this project, or null if all done / no list.
  int? nextStepIndex(String project) {
    final c = activeChecklist;
    if (c == null) return null;
    final done = completedSteps(project);
    for (var i = 0; i < c.steps.length; i++) {
      if (!done.contains(i)) return i;
    }
    return null;
  }
  String get reference => _reference;
  String get inspector => _inspector;

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
    final mode = (prefs.getInt(_kLocationMode) ?? 0)
        .clamp(0, StampLocationMode.values.length - 1)
        .toInt();
    s._locationMode = StampLocationMode.values[mode];
    try {
      final raw = prefs.getString(_kSites);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        s._sites = {
          for (final e in map.entries)
            e.key: SiteLocation.fromJson(e.value as Map<String, dynamic>),
        };
      }
    } catch (_) {}
    try {
      final raw = prefs.getString(_kChecklists);
      if (raw != null && raw.isNotEmpty) {
        s._customChecklists = [
          for (final e in (jsonDecode(raw) as List))
            Checklist.fromJson(e as Map<String, dynamic>),
        ];
      }
      final prog = prefs.getString(_kProgress);
      if (prog != null && prog.isNotEmpty) {
        final map = jsonDecode(prog) as Map<String, dynamic>;
        s._progress = {
          for (final e in map.entries)
            e.key: [for (final v in (e.value as List)) (v as num).toInt()],
        };
      }
    } catch (_) {}
    s._activeChecklistId = prefs.getString(_kActiveChecklist) ?? '';
    s._company = prefs.getString(_kCompany) ?? '';
    s._reference = prefs.getString(_kReference) ?? '';
    s._inspector = prefs.getString(_kInspector) ?? '';
    final theme = (prefs.getInt(_kStampTheme) ?? 0)
        .clamp(0, StampTheme.values.length - 1)
        .toInt();
    s._style = StampStyle(
      position: StampPosition.values[pos],
      size: StampSize.values[size],
      theme: StampTheme.values[theme],
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
    _sites.remove(name);
    notifyListeners();
    await _saveSites();
    await _prefs.setStringList(_kProjects, _projects);
    await _prefs.setString(_kProject, _project);
  }

  Future<void> setLocationMode(StampLocationMode mode) async {
    _locationMode = mode;
    notifyListeners();
    await _prefs.setInt(_kLocationMode, mode.index);
  }

  Future<void> _saveSites() => _prefs.setString(
        _kSites,
        jsonEncode({for (final e in _sites.entries) e.key: e.value.toJson()}),
      );

  Future<void> setSite(String project, SiteLocation? site) async {
    if (site == null) {
      _sites.remove(project);
    } else {
      _sites[project] = site;
    }
    notifyListeners();
    await _saveSites();
  }

  Future<void> _saveChecklists() => _prefs.setString(
        _kChecklists,
        jsonEncode([for (final c in _customChecklists) c.toJson()]),
      );

  Future<void> _saveProgress() => _prefs.setString(_kProgress, jsonEncode(_progress));

  Future<void> setActiveChecklist(String? id) async {
    _activeChecklistId = id ?? '';
    notifyListeners();
    await _prefs.setString(_kActiveChecklist, _activeChecklistId);
  }

  /// Creates a custom checklist and makes it the active one.
  Future<void> addChecklist(String name, List<String> steps) async {
    final n = name.trim().isEmpty ? 'My checklist' : name.trim();
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    _customChecklists = [..._customChecklists, Checklist(id: id, name: n, steps: steps)];
    _activeChecklistId = id;
    notifyListeners();
    await _saveChecklists();
    await _prefs.setString(_kActiveChecklist, _activeChecklistId);
  }

  Future<void> removeChecklist(String id) async {
    _customChecklists = _customChecklists.where((c) => c.id != id).toList();
    _progress.removeWhere((k, _) => k.endsWith('|$id'));
    if (_activeChecklistId == id) _activeChecklistId = '';
    notifyListeners();
    await _saveChecklists();
    await _saveProgress();
    await _prefs.setString(_kActiveChecklist, _activeChecklistId);
  }

  Future<void> markStepDone(String project, int index) async {
    final key = _progressKey(project);
    final list = {...(_progress[key] ?? const <int>[]), index}.toList()..sort();
    _progress[key] = list;
    notifyListeners();
    await _saveProgress();
  }

  Future<void> resetProgress(String project) async {
    _progress.remove(_progressKey(project));
    notifyListeners();
    await _saveProgress();
  }

  Future<void> setStampTheme(StampTheme t) async {
    _style = _style.copyWith(theme: t);
    notifyListeners();
    await _prefs.setInt(_kStampTheme, t.index);
  }

  Future<void> setStampText({
    required String company,
    required String reference,
    required String inspector,
  }) async {
    _company = company.trim();
    _reference = reference.trim();
    _inspector = inspector.trim();
    notifyListeners();
    await _prefs.setString(_kCompany, _company);
    await _prefs.setString(_kReference, _reference);
    await _prefs.setString(_kInspector, _inspector);
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
