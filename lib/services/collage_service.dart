import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../models/library_item.dart';
import '../models/stamp_data.dart';

/// Builds a side-by-side BEFORE / AFTER image from two library photos.
class CollageService {
  static const int _cellHeight = 1200;
  static const double _header = 120;
  static const double _gap = 12;

  static Future<ui.Image> _decode(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetHeight: _cellHeight);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static void _label(
    Canvas canvas,
    String title,
    String time,
    double x,
    double width,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$title\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: time,
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 26),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width - 32);
    tp.paint(canvas, Offset(x + 16, 12));
  }

  /// Returns the path of the finished JPEG (in the app cache).
  static Future<String> build({
    required LibraryItem before,
    required LibraryItem after,
  }) async {
    final a = await _decode(before.path);
    final b = await _decode(after.path);
    final w = a.width + _gap + b.width;
    final h = _header + _cellHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF151515),
    );
    canvas.drawImage(a, Offset(0, _header), Paint());
    canvas.drawImage(b, Offset(a.width + _gap, _header), Paint());
    _label(
      canvas,
      'BEFORE',
      StampData.formatTime(before.data.time),
      0,
      a.width.toDouble(),
    );
    _label(
      canvas,
      'AFTER',
      StampData.formatTime(after.data.time),
      a.width + _gap,
      b.width.toDouble(),
    );

    final picture = recorder.endRecording();
    final out = await picture.toImage(w.round(), h.round());
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    final outW = out.width;
    final outH = out.height;
    picture.dispose();
    a.dispose();
    b.dispose();
    out.dispose();
    if (png == null) throw StateError('Could not encode collage');

    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/collage');
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final id = DateTime.now().millisecondsSinceEpoch;
    final pngPath = '${dir.path}/ba_$id.png';
    final jpgPath = '${dir.path}/SiteStamp_before_after_$id.jpg';
    await File(pngPath).writeAsBytes(
      png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
      flush: true,
    );
    final jpg = await FlutterImageCompress.compressAndGetFile(
      pngPath,
      jpgPath,
      quality: 90,
      minWidth: outW,
      minHeight: outH,
      autoCorrectionAngle: false,
      keepExif: false,
      format: CompressFormat.jpeg,
    );
    if (jpg == null) return pngPath;
    try {
      await File(pngPath).delete();
    } catch (_) {}
    return jpg.path;
  }
}
