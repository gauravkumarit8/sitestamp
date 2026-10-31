import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/library_item.dart';
import '../models/stamp_data.dart';

class PdfPhoto {
  const PdfPhoto({required this.path, required this.caption});
  final String path;
  final String caption;
}

/// CSV and PDF reports of stamped photos.
class ExportService {
  static const int maxPdfPhotos = 60;

  // ---------- CSV ----------
  static String csvEscape(String v) {
    if (v.contains(RegExp(r'[",\r\n]'))) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String buildCsv(List<LibraryItem> items) {
    const header = [
      'file_name',
      'date_time',
      'time_zone',
      'project',
      'latitude',
      'longitude',
      'altitude_m',
      'accuracy_m',
      'address',
      'note',
      'mock_location',
      'company',
      'reference',
      'inspector',
    ];
    final rows = <String>[header.join(',')];
    for (final it in items) {
      final d = it.data;
      rows.add(
        [
          d.fileName,
          StampData.isoLocal(d.time),
          StampData.tzLabel(d.time),
          d.project,
          d.latitude?.toStringAsFixed(6) ?? '',
          d.longitude?.toStringAsFixed(6) ?? '',
          d.altitude?.round().toString() ?? '',
          d.accuracy?.round().toString() ?? '',
          d.address ?? '',
          d.memo,
          d.isMocked ? 'yes' : 'no',
          d.company,
          d.reference,
          d.inspector,
        ].map(csvEscape).join(','),
      );
    }
    // BOM so Excel opens UTF-8 (e.g. Hindi notes) correctly.
    return '\uFEFF${rows.join('\r\n')}\r\n';
  }

  // ---------- PDF ----------
  /// The default PDF font only supports Latin-1; replace other characters.
  static String pdfSafe(String s) => String.fromCharCodes(
        s.runes.map((r) => r == 10 ? 10 : ((r >= 32 && r <= 0xFF) ? r : 63)),
      );

  static String captionFor(int index, LibraryItem item) {
    final d = item.data;
    final lines = <String>[
      '#$index  ${StampData.formatTime(d.time)}',
      if (d.company.trim().isNotEmpty) d.company.trim(),
      if (d.project.trim().isNotEmpty) 'Project: ${d.project.trim()}',
      if (d.reference.trim().isNotEmpty || d.inspector.trim().isNotEmpty)
        [
          if (d.reference.trim().isNotEmpty) 'Ref: ${d.reference.trim()}',
          if (d.inspector.trim().isNotEmpty) 'By: ${d.inspector.trim()}',
        ].join('   '),
      if ((d.address ?? '').trim().isNotEmpty)
        _clip(d.address!.trim(), 120),
      if (d.hasFix)
        'Lat ${d.latitude!.toStringAsFixed(6)}  Lon ${d.longitude!.toStringAsFixed(6)}'
            '${d.accuracy != null ? '  (+/-${d.accuracy!.round()} m)' : ''}',
      if (d.memo.isNotEmpty) 'Note: ${_clip(d.memo, 120)}',
    ];
    return pdfSafe(lines.join('\n'));
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}...';

  static String subtitleFor(List<LibraryItem> chronological, String? label) {
    final first = chronological.first.data.time;
    final last = chronological.last.data.time;
    String day(DateTime t) => StampData.isoLocal(t).substring(0, 10);
    final range = day(first) == day(last) ? day(first) : '${day(first)} to ${day(last)}';
    return pdfSafe(
      '${label == null || label.isEmpty ? 'All photos' : 'Project: $label'}'
      '  |  ${chronological.length} photos  |  $range  |  Made with SiteStamp',
    );
  }

  static Future<Uint8List> renderPdf(
    String title,
    String subtitle,
    List<PdfPhoto> photos,
  ) async {
    final doc = pw.Document(title: title, creator: 'SiteStamp');
    final cells = <pw.Widget>[];
    for (final p in photos) {
      final bytes = await File(p.path).readAsBytes();
      cells.add(
        pw.Container(
          width: 240,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 240,
                height: 320,
                child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(height: 4),
              pw.Text(p.caption, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      );
    }
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (ctx) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Wrap(spacing: 12, runSpacing: 12, children: cells),
        ],
      ),
    );
    return doc.save();
  }

  // ---------- files + sharing ----------
  static String _safeName(String? label) {
    final base = (label == null || label.trim().isEmpty) ? 'All' : label.trim();
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return cleaned.length > 30 ? cleaned.substring(0, 30) : cleaned;
  }

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}';
  }

  static Future<Directory> _exportDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/exports');
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    return dir;
  }

  static Future<String> exportCsv(
    List<LibraryItem> items, {
    String? projectLabel,
  }) async {
    final chronological = [...items]
      ..sort((a, b) => a.data.time.compareTo(b.data.time));
    final dir = await _exportDir();
    final path =
        '${dir.path}/SiteStamp_${_safeName(projectLabel)}_${_stamp(DateTime.now())}.csv';
    await File(path).writeAsString(buildCsv(chronological), flush: true);
    return path;
  }

  /// Returns the PDF path. Uses at most [maxPdfPhotos] (the newest ones).
  static Future<String> exportPdf(
    List<LibraryItem> items, {
    String? projectLabel,
  }) async {
    final newest = [...items]..sort((a, b) => b.data.time.compareTo(a.data.time));
    final chosen = newest.take(maxPdfPhotos).toList()
      ..sort((a, b) => a.data.time.compareTo(b.data.time));
    final title = pdfSafe(
      projectLabel == null || projectLabel.isEmpty
          ? 'SiteStamp photo report'
          : 'SiteStamp report: $projectLabel',
    );
    final subtitle = subtitleFor(chosen, projectLabel);
    final photos = <PdfPhoto>[
      for (var i = 0; i < chosen.length; i++)
        PdfPhoto(path: chosen[i].path, caption: captionFor(i + 1, chosen[i])),
    ];
    // Heavy work off the UI thread.
    final bytes = await Isolate.run(() => renderPdf(title, subtitle, photos));
    final dir = await _exportDir();
    final path =
        '${dir.path}/SiteStamp_${_safeName(projectLabel)}_${_stamp(DateTime.now())}.pdf';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  static Future<void> shareFile(String path, String mimeType, {String? text}) {
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'SiteStamp export',
        files: [XFile(path, mimeType: mimeType)],
      ),
    );
  }
}
