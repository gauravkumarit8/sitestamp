import 'package:flutter_test/flutter_test.dart';
import 'package:sitestamp/models/stamp_data.dart';
import 'package:sitestamp/services/address_service.dart';

void main() {
  test('stamp lines with GPS fix and memo', () {
    final d = StampData(
      time: DateTime(2026, 10, 28, 14, 32, 5),
      memo: 'Gate 3',
      latitude: 28.6123456,
      longitude: 77.2090123,
      altitude: 215.4,
      accuracy: 4.6,
    );
    final lines = d.toLines();
    expect(lines.first, startsWith('28 Oct 2026  14:32:05'));
    expect(lines[1], 'Lat 28.612346  Lon 77.209012');
    expect(lines[2], 'Alt 215 m   Accuracy ±5 m');
    expect(lines.last, 'Note: Gate 3');
    expect(d.fileName, 'SiteStamp_20261028_143205.jpg');
  });

  test('stamp lines include address right after the time', () {
    final d = StampData(
      time: DateTime(2026, 10, 28, 14, 32, 5),
      memo: '',
      latitude: 28.6,
      longitude: 77.2,
      accuracy: 5,
      address: 'MG Road, Pune',
    );
    final lines = d.toLines();
    expect(lines[1], 'MG Road, Pune');
    expect(lines[2], startsWith('Lat '));
  });

  test('address is not printed without a GPS fix', () {
    final d = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: '',
      address: 'Somewhere',
    );
    expect(d.toLines(), isNot(contains('Somewhere')));
  });

  test('stamp lines without GPS fix', () {
    final d = StampData(time: DateTime(2026, 1, 2, 3, 4, 5), memo: '');
    final lines = d.toLines();
    expect(lines.length, 2);
    expect(lines[1], 'GPS location unavailable');
  });

  test('joinParts skips empty and duplicate parts', () {
    expect(
      AddressService.joinParts(['MG Road', null, ' ', 'Pune', 'Pune', 'MH']),
      'MG Road, Pune, MH',
    );
    expect(AddressService.joinParts([null, '']), '');
  });

  test('free plan adds a branding line last', () {
    final d = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: 'Hi',
      latitude: 1,
      longitude: 2,
      branding: true,
    );
    expect(d.toLines().last, 'Made with SiteStamp');
    final pro = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: 'Hi',
      latitude: 1,
      longitude: 2,
    );
    expect(pro.toLines().last, 'Note: Hi');
  });
}
