import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_language.dart';
import '../models/saved_photo.dart';
import '../models/stamp_data.dart';
import '../services/photo_library.dart';
import '../widgets/tx.dart';

enum AnnotationTool { pen, arrow, circle }

class AnnotationShape {
  AnnotationShape(this.tool, this.color, this.points);

  final AnnotationTool tool;
  final Color color;

  /// Image coordinates. Pen: the whole path. Arrow/circle: [start, end].
  final List<Offset> points;
}

/// Draws all shapes onto [canvas] (already in image coordinates).
void paintAnnotations(
  Canvas canvas,
  List<AnnotationShape> shapes,
  double strokeWidth,
) {
  for (final s in shapes) {
    if (s.points.isEmpty) continue;
    final paint = Paint()
      ..color = s.color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (s.tool) {
      case AnnotationTool.pen:
        if (s.points.length == 1) {
          canvas.drawCircle(
            s.points.first,
            strokeWidth / 2,
            Paint()..color = s.color,
          );
        } else {
          final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
          for (final p in s.points.skip(1)) {
            path.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(path, paint);
        }
      case AnnotationTool.arrow:
        final a = s.points.first;
        final b = s.points.last;
        if ((b - a).distance < 2) break;
        canvas.drawLine(a, b, paint);
        final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
        final head = strokeWidth * 5;
        for (final d in [math.pi * 5 / 6, -math.pi * 5 / 6]) {
          canvas.drawLine(
            b,
            b + Offset(math.cos(angle + d) * head, math.sin(angle + d) * head),
            paint,
          );
        }
      case AnnotationTool.circle:
        if ((s.points.last - s.points.first).distance < 2) break;
        canvas.drawOval(Rect.fromPoints(s.points.first, s.points.last), paint);
    }
  }
}

class _ShapesPainter extends CustomPainter {
  _ShapesPainter(this.shapes, this.scale, this.strokeWidth);

  final List<AnnotationShape> shapes;
  final double scale;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    paintAnnotations(canvas, shapes, strokeWidth);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Mark problems on a photo. Saves a NEW copy; the original is never changed.
class AnnotateScreen extends StatefulWidget {
  const AnnotateScreen({super.key, required this.photo, required this.library});

  final SavedPhoto photo;
  final PhotoLibrary library;

  @override
  State<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends State<AnnotateScreen> {
  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFFFFEB3B),
    Color(0xFFFFFFFF),
    Color(0xFF1E88E5),
  ];

  ui.Image? _image;
  String? _error;
  final List<AnnotationShape> _shapes = [];
  AnnotationShape? _current;
  AnnotationTool _tool = AnnotationTool.arrow;
  Color _color = _palette.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.photo.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the photo.');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Tx(msg)));
  }

  void _start(Offset p) =>
      setState(() => _current = AnnotationShape(_tool, _color, [p]));

  void _update(Offset p) {
    final c = _current;
    if (c == null) return;
    setState(() {
      if (c.tool == AnnotationTool.pen) {
        c.points.add(p);
      } else if (c.points.length == 1) {
        c.points.add(p);
      } else {
        c.points[1] = p;
      }
    });
  }

  void _end() {
    final c = _current;
    if (c == null) return;
    setState(() {
      _shapes.add(c);
      _current = null;
    });
  }

  Future<void> _save() async {
    final img = _image;
    if (img == null || _saving) return;
    if (_shapes.isEmpty) {
      _toast('Draw something first.');
      return;
    }
    setState(() => _saving = true);
    String? pngPath;
    String? jpgPath;
    try {
      final w = img.width.toDouble();
      final h = img.height.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
      canvas.drawImage(img, Offset.zero, Paint());
      paintAnnotations(canvas, _shapes, math.max(4.0, w * 0.006));
      final picture = recorder.endRecording();
      final out = await picture.toImage(img.width, img.height);
      final png = await out.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      out.dispose();
      if (png == null) throw StateError('encode failed');

      final tmp = await getTemporaryDirectory();
      final base = widget.photo.data.fileName.replaceAll('.jpg', '_annotated');
      pngPath = '${tmp.path}/$base.png';
      jpgPath = '${tmp.path}/$base.jpg';
      await File(pngPath).writeAsBytes(
        png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        flush: true,
      );
      final jpg = await FlutterImageCompress.compressAndGetFile(
        pngPath,
        jpgPath,
        quality: 92,
        minWidth: img.width,
        minHeight: img.height,
        autoCorrectionAngle: false,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      final finalPath = jpg?.path ?? pngPath;
      final hash = sha256.convert(await File(finalPath).readAsBytes()).toString();

      try {
        await Gal.putImage(
          finalPath,
          album: StampData.albumFor(widget.photo.data.project),
        );
      } catch (_) {
        // gallery access may be missing; the in-app copy is still kept
      }
      await widget.library.add(
        sourcePath: finalPath,
        data: widget.photo.data.markAnnotated(),
        sha256: hash,
      );
      _toast('Annotated copy saved.');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _toast('Could not save the annotated copy.');
    } finally {
      for (final p in [pngPath, jpgPath]) {
        if (p == null) continue;
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  String _toolLabel(AnnotationTool t) {
    switch (t) {
      case AnnotationTool.pen:
        return 'Pen';
      case AnnotationTool.arrow:
        return 'Arrow';
      case AnnotationTool.circle:
        return 'Circle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Tx('Annotate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: tr('Undo'),
            onPressed: _shapes.isEmpty ? null : () => setState(_shapes.removeLast),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: tr('Clear'),
            onPressed: _shapes.isEmpty ? null : () => setState(_shapes.clear),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Tx('Save copy'),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Tx(_error!, style: const TextStyle(color: Colors.white)))
          : img == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final iw = img.width.toDouble();
                          final ih = img.height.toDouble();
                          final scale = math.min(c.maxWidth / iw, c.maxHeight / ih);
                          final dw = iw * scale;
                          final dh = ih * scale;
                          final stroke = math.max(4.0, iw * 0.006);
                          return Center(
                            child: GestureDetector(
                              onPanStart: (d) => _start(d.localPosition / scale),
                              onPanUpdate: (d) => _update(d.localPosition / scale),
                              onPanEnd: (_) => _end(),
                              child: SizedBox(
                                width: dw,
                                height: dh,
                                child: Stack(
                                  children: [
                                    RawImage(
                                      image: img,
                                      width: dw,
                                      height: dh,
                                      fit: BoxFit.fill,
                                    ),
                                    CustomPaint(
                                      size: Size(dw, dh),
                                      painter: _ShapesPainter(
                                        [..._shapes, if (_current != null) _current!],
                                        scale,
                                        stroke,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildToolbar(),
                  ],
                ),
    );
  }

  Widget _buildToolbar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final t in AnnotationTool.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Tx(_toolLabel(t)),
                      selected: _tool == t,
                      onSelected: (_) => setState(() => _tool = t),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.white : Colors.white24,
                          width: _color == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Tx(
              'Draw on the photo to mark problems. The original stays unchanged.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
