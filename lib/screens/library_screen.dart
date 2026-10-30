import 'dart:io';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

import '../models/library_item.dart';
import '../services/billing_service.dart';
import '../services/entitlements.dart';
import '../services/export_service.dart';
import '../services/photo_library.dart';
import 'photo_preview_screen.dart';
import 'pro_screen.dart';

enum _ExportKind { pdf, csv }

/// Grid of photos kept inside the app, with project filter, multi-select,
/// share, remove, and (Pro) PDF/CSV export.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.library,
    required this.entitlements,
    required this.billing,
  });

  final PhotoLibrary library;
  final Entitlements entitlements;
  final BillingService billing;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<LibraryItem> _all = const [];
  bool _loading = true;
  String? _filter; // null = all, '' = default (no project), else project name
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    widget.library.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    widget.library.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final items = await widget.library.list();
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
      _selected.removeWhere((id) => !items.any((i) => i.id == id));
    });
  }

  List<LibraryItem> get _visible {
    if (_filter == null) return _all;
    return _all.where((i) => i.data.project.trim() == _filter).toList();
  }

  List<String> get _projects {
    final names = <String>{
      for (final i in _all)
        if (i.data.project.trim().isNotEmpty) i.data.project.trim(),
    };
    return names.toList()..sort();
  }

  List<LibraryItem> get _targets {
    if (_selected.isEmpty) return _visible;
    return _all.where((i) => _selected.contains(i.id)).toList();
  }

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(LibraryItem it) {
    setState(() {
      if (!_selected.remove(it.id)) _selected.add(it.id);
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _shareSelected() async {
    final items = _targets;
    if (items.isEmpty) return;
    if (items.length > 20) {
      _toast('Select up to 20 photos to share at once.');
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'SiteStamp photos',
          text: items.length == 1
              ? items.first.toSavedPhoto().shareText
              : '${items.length} photos from SiteStamp',
          files: [for (final i in items) XFile(i.path, mimeType: 'image/jpeg')],
        ),
      );
    } catch (_) {
      _toast('Could not open the share sheet.');
    }
  }

  Future<void> _deleteSelected() async {
    final items = _targets;
    if (items.isEmpty || !_selecting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${items.length} photo${items.length == 1 ? '' : 's'}?'),
        content: const Text(
          'They are removed from this list only. The copies in your phone '
          'gallery are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.library.deleteAll(items);
    if (mounted) setState(_selected.clear);
  }

  Future<void> _export(_ExportKind kind) async {
    if (!widget.entitlements.canExport) {
      _openPro();
      return;
    }
    final items = _targets;
    if (items.isEmpty) {
      _toast('No photos to export.');
      return;
    }
    final label = _selecting
        ? null
        : (_filter == null || _filter!.isEmpty ? null : _filter);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                kind == _ExportKind.pdf
                    ? 'Building PDF...'
                    : 'Building spreadsheet...',
              ),
            ),
          ],
        ),
      ),
    );
    String? path;
    String? error;
    try {
      path = kind == _ExportKind.pdf
          ? await ExportService.exportPdf(items, projectLabel: label)
          : await ExportService.exportCsv(items, projectLabel: label);
    } catch (e) {
      error = 'Export failed. Try fewer photos.';
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (error != null || path == null) {
      _toast(error ?? 'Export failed.');
      return;
    }
    if (kind == _ExportKind.pdf && items.length > ExportService.maxPdfPhotos) {
      _toast('PDF includes the newest ${ExportService.maxPdfPhotos} photos.');
    }
    try {
      await ExportService.shareFile(
        path,
        kind == _ExportKind.pdf ? 'application/pdf' : 'text/csv',
      );
    } catch (_) {
      _toast('Could not open the share sheet.');
    }
  }

  void _openPro() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProScreen(
          billing: widget.billing,
          entitlements: widget.entitlements,
        ),
      ),
    );
  }

  void _open(LibraryItem it) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoPreviewScreen(photo: it.toSavedPhoto()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      appBar: AppBar(
        leading: _selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selected.clear),
              )
            : null,
        title: Text(_selecting ? '${_selected.length} selected' : 'Photos'),
        actions: [
          if (_selecting) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _shareSelected,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove from app',
              onPressed: _deleteSelected,
            ),
          ],
          PopupMenuButton<_ExportKind>(
            icon: Icon(
              widget.entitlements.canExport
                  ? Icons.file_download_outlined
                  : Icons.lock_outline,
            ),
            tooltip: 'Export',
            onSelected: _export,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ExportKind.pdf,
                child: Text('PDF report'),
              ),
              PopupMenuItem(
                value: _ExportKind.csv,
                child: Text('CSV spreadsheet'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_projects.isNotEmpty) _buildFilters(),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No photos here yet. Photos you take with '
                              'SiteStamp appear in this list.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) => _cell(items[index]),
                        ),
                ),
                if (!widget.entitlements.isPro)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      'Free plan keeps your latest 50 photos in this list. '
                      'All photos stay in your phone gallery. Pro keeps '
                      'everything and adds PDF/CSV export.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    final chips = <MapEntry<String?, String>>[
      const MapEntry(null, 'All'),
      const MapEntry('', 'Default'),
      for (final p in _projects) MapEntry(p, p),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = chips[index];
          return ChoiceChip(
            label: Text(c.value),
            selected: _filter == c.key,
            onSelected: (_) => setState(() {
              _filter = c.key;
              _selected.clear();
            }),
          );
        },
      ),
    );
  }

  Widget _cell(LibraryItem it) {
    final selected = _selected.contains(it.id);
    return GestureDetector(
      onTap: () => _selecting ? _toggle(it) : _open(it),
      onLongPress: () => _toggle(it),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(it.path),
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (context, error, stack) =>
                const Icon(Icons.image_not_supported_outlined),
          ),
          if (selected)
            Container(
              color: const Color(0x66FF8F00),
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.check_circle, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
