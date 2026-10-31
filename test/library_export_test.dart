import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sitestamp/models/library_item.dart';
import 'package:sitestamp/models/stamp_data.dart';
import 'package:sitestamp/services/export_service.dart';
import 'package:sitestamp/services/photo_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StampData json round trip', () {
    final d = StampData(
      time: DateTime(2026, 10, 28, 14, 32, 5),
      memo: 'Gate 3',
      latitude: 28.6123456,
      longitude: 77.2090123,
      altitude: 215.4,
      accuracy: 4.6,
      isMocked: true,
      address: 'MG Road, Pune',
      branding: true,
      project: 'Tower A',
    );
    final back = StampData.fromJson(d.toJson());
    expect(back.toLines(), d.toLines());
    expect(back.project, 'Tower A');
    expect(back.isMocked, isTrue);
    expect(back.branding, isTrue);
  });

  test('csvEscape quotes commas, quotes and newlines', () {
    expect(ExportService.csvEscape('plain'), 'plain');
    expect(ExportService.csvEscape('a,b'), '"a,b"');
    expect(ExportService.csvEscape('say "hi"'), '"say ""hi"""');
    expect(ExportService.csvEscape('l1\nl2'), '"l1\nl2"');
  });

  test('buildCsv has BOM, header and one row per photo', () {
    final items = [
      LibraryItem(
        id: '1',
        path: '/x/1.jpg',
        data: StampData(
          time: DateTime(2026, 1, 2, 3, 4, 5),
          memo: 'a,b',
          project: 'Tower A',
          latitude: 1.5,
          longitude: 2.5,
          altitude: 10.4,
          accuracy: 4.6,
        ),
      ),
      LibraryItem(
        id: '2',
        path: '/x/2.jpg',
        data: StampData(time: DateTime(2026, 1, 2, 3, 4, 6), memo: ''),
      ),
    ];
    final csv = ExportService.buildCsv(items);
    expect(csv.startsWith('\uFEFFfile_name,date_time,time_zone,project'), isTrue);
    final lines = csv.trim().split('\r\n');
    expect(lines.length, 3);
    expect(lines.first.endsWith('mock_location,company,reference,inspector'), isTrue);
    expect(lines[1], contains('2026-01-02 03:04:05'));
    expect(lines[1], contains('Tower A,1.500000,2.500000,10,5'));
    expect(lines[1], contains('"a,b"'));
    expect(lines[2], contains(',,,,'));
  });

  test('pdfSafe keeps Latin-1 and replaces other characters', () {
    expect(ExportService.pdfSafe('Note: ±5 m'), 'Note: ±5 m');
    expect(ExportService.pdfSafe('नमस्ते'), '??????');
    expect(ExportService.pdfSafe('a\nb'), 'a\nb');
  });

  test('captionFor contains index, time, coordinates and note', () {
    final item = LibraryItem(
      id: '1',
      path: '/x/1.jpg',
      data: StampData(
        time: DateTime(2026, 10, 28, 14, 32, 5),
        memo: 'Gate 3',
        latitude: 28.6,
        longitude: 77.2,
        accuracy: 5,
      ),
    );
    final c = ExportService.captionFor(3, item);
    expect(c, startsWith('#3  28 Oct 2026'));
    expect(c, contains('Lat 28.600000'));
    expect(c, contains('Note: Gate 3'));
  });

  test('photo library add, list, prune and delete', () async {
    final root = Directory.systemTemp.createTempSync('ss_lib_test');
    addTearDown(() => root.deleteSync(recursive: true));
    final lib = PhotoLibrary(directory: Directory('${root.path}/lib'));
    final src = File('${root.path}/src.jpg')..writeAsBytesSync([1, 2, 3]);

    Future<LibraryItem?> addAt(int sec) => lib.add(
          sourcePath: src.path,
          data: StampData(
            time: DateTime(2026, 1, 1, 0, 0, sec),
            memo: 'n$sec',
          ),
        );

    expect(await addAt(1), isNotNull);
    await addAt(2);
    await addAt(3);

    var items = await lib.list();
    expect(items.length, 3);
    expect(items.first.data.memo, 'n3'); // newest first

    await lib.prune(2);
    items = await lib.list();
    expect(items.length, 2);
    expect(items.last.data.memo, 'n2');

    await lib.deleteAll(items);
    expect(await lib.list(), isEmpty);
  });
}
