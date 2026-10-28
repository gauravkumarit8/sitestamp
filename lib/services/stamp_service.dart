import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';

import '../models/stamp_data.dart';

/// Capture -> downscale + upright -> draw stamp -> JPEG -> EXIF GPS -> gallery.
///
/// Orientation strategy: pixels are rotated upright ONCE in step 1 and EXIF is
/// stripped, so there is no orientation flag left to be misread (or applied
/// twice) by Samsung Gallery, Google Photos or iOS Photos.
class StampService {
  static const int _maxSide = 1920;
  static const int _jpegQuality = 92;
  static const String albumName = 'SiteStamp';

  static Future<void> stampAndSave({
    required String rawPath,
    required StampData data,
  }) async {
    final tmp = await getTemporaryDirectory();
    final id = DateTime.now().microsecondsSinceEpoch;
    final scaledPath = '${tmp.path}/ss_scaled_$id.jpg';
    final stampedPngPath = '${tmp.path}/ss_stamped_$id.png';
    final finalPath = '${tmp.path}/${data.fileName}';

    try {
      // 1. Downscale + rotate upright, off the UI thread (native), no EXIF kept.
      final scaled = await FlutterImageCompress.compressAndGetFile(
        rawPath,
        scaledPath,
        minWidth: _maxSide,
        minHeight: _maxSide,
        quality: 90,
        autoCorrectionAngle: true,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (scaled == null) {
        throw StateError('Image compression failed');
      }

      // 2. Draw the stamp onto the downscaled bitmap.
      final size = await _drawStamp(scaled.path, stampedPngPath, data);

      // 3. Encode final JPEG without resizing again.
      final out = await FlutterImageCompress.compressAndGetFile(
        stampedPngPath,
        finalPath,
        minWidth: size.width.round(),
        minHeight: size.height.round(),
        quality: _jpegQuality,
        autoCorrectionAngle: false,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (out == null) {
        throw StateError('Final encode failed');
      }

      // 4. Write GPS into EXIF (best effort, never blocks saving).
      if (data.hasFix) {
        Exif? exif;
        try {
          exif = await Exif.fromPath(out.path);
          await exif.writeAttributes(<String, Object>{
            'GPSLatitude': data.latitude!.abs(),
            'GPSLatitudeRef': data.latitude! >= 0 ? 'N' : 'S',
            'GPSLongitude': data.longitude!.abs(),
            'GPSLongitudeRef': data.longitude! >= 0 ? 'E' : 'W',
          });
        } catch (_) {
          // Stamp is already burned into the pixels; EXIF is a bonus.
        } finally {
          await exif?.close();
        }
      }

      // 5. Save to the public gallery.
      await Gal.putImage(out.path, album: albumName);
    } finally {
      // 6. Always clean temp files.
      await _safeDelete(rawPath);
      await _safeDelete(scaledPath);
      await _safeDelete(stampedPngPath);
      await _safeDelete(finalPath);
    }
  }

  static Future<ui.Size> _drawStamp(
    String srcPath,
    String outPath,
    StampData data,
  ) async {
    final bytes = await File(srcPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;

    final w = image.width.toDouble();
    final h = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawImage(image, Offset.zero, Paint());

    final pad = w * 0.03;
    final fontSize = w * 0.034;
    final lines = data.toLines();

    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      spans.add(
        TextSpan(
          text: i < lines.length - 1 ? '${lines[i]}\n' : lines[i],
          style: TextStyle(
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
            color: lines[i].startsWith('WARNING')
                ? const Color(0xFFFF5252)
                : const Color(0xFFFFFFFF),
          ),
        ),
      );
    }

    final painter = TextPainter(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, height: 1.25),
        children: spans,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 12,
      ellipsis: '…',
    )..layout(maxWidth: w - 2 * pad);

    final panelHeight = painter.height + pad * 1.2;
    final top = h - panelHeight;
    canvas.drawRect(
      Rect.fromLTWH(0, top, w, panelHeight),
      Paint()..color = const Color(0x99000000),
    );
    painter.paint(canvas, Offset(pad, top + pad * 0.6));

    final picture = recorder.endRecording();
    final stamped = await picture.toImage(image.width, image.height);
    final byteData = await stamped.toByteData(format: ui.ImageByteFormat.png);

    picture.dispose();
    image.dispose();
    stamped.dispose();

    if (byteData == null) {
      throw StateError('Could not encode stamped image');
    }
    await File(outPath).writeAsBytes(
      byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      flush: true,
    );
    return ui.Size(w, h);
  }

  static Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
