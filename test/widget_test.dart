import 'package:flutter_test/flutter_test.dart';
import 'package:sitestamp/models/photo_id.dart';
import 'package:sitestamp/models/saved_photo.dart';
import 'package:sitestamp/models/site_location.dart';
import 'package:sitestamp/models/stamp_data.dart';
import 'package:sitestamp/models/stamp_style.dart';
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

  test('project line appears after the time', () {
    final d = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: '',
      project: 'Tower A',
      latitude: 1,
      longitude: 2,
    );
    expect(d.toLines()[1], 'Project: Tower A');
  });

  test('album names are safe and prefixed', () {
    expect(StampData.albumFor(''), 'SiteStamp');
    expect(StampData.albumFor('  '), 'SiteStamp');
    expect(StampData.albumFor('Tower A'), 'SiteStamp - Tower A');
    expect(StampData.albumFor('a/b:c*d'), 'SiteStamp - a b c d');
    expect(StampData.albumFor('x' * 60).length, 'SiteStamp - '.length + 40);
  });

  test('stamp style defaults and scale', () {
    const s = StampStyle();
    expect(s.position, StampPosition.bottom);
    expect(s.size, StampSize.medium);
    expect(StampSize.large.fontFactor > StampSize.small.fontFactor, isTrue);
    expect(s.copyWith(position: StampPosition.top).position, StampPosition.top);
  });

  test('share text has address, maps link and note', () {
    final photo = SavedPhoto(
      path: '/tmp/x.jpg',
      data: StampData(
        time: DateTime(2026, 10, 28, 14, 32, 5),
        memo: 'Gate 3',
        project: 'Tower A',
        latitude: 28.6123456,
        longitude: 77.2090123,
        address: 'MG Road, Pune',
      ),
    );
    final lines = photo.shareText.split('\n');
    expect(lines[0], startsWith('28 Oct 2026'));
    expect(lines, contains('Project: Tower A'));
    expect(lines, contains('MG Road, Pune'));
    expect(lines, contains('https://maps.google.com/?q=28.612346,77.209012'));
    expect(lines.last, 'Note: Gate 3');
  });

  test('share text without GPS has no maps link', () {
    final photo = SavedPhoto(
      path: '/tmp/x.jpg',
      data: StampData(time: DateTime(2026, 1, 2, 3, 4, 5), memo: ''),
    );
    expect(photo.shareText.contains('maps.google.com'), isFalse);
  });

  test('location mode: name replaces coordinates, falls back when no name', () {
    StampData make(StampLocationMode m, {String? address}) => StampData(
          time: DateTime(2026, 1, 2, 3, 4, 5),
          memo: '',
          latitude: 26.1,
          longitude: 85.3,
          accuracy: 10,
          address: address,
          locationMode: m,
        );
    final nameOnly = make(StampLocationMode.addressFirst, address: 'Station Rd, Muzaffarpur').toLines();
    expect(nameOnly.any((l) => l.startsWith('Lat ')), isFalse);
    expect(nameOnly, contains('Station Rd, Muzaffarpur'));
    expect(nameOnly.any((l) => l.contains('Accuracy')), isTrue);

    final fallback = make(StampLocationMode.addressFirst).toLines();
    expect(fallback.any((l) => l.startsWith('Lat ')), isTrue);

    final both = make(StampLocationMode.both, address: 'Station Rd').toLines();
    expect(both, contains('Station Rd'));
    expect(both.any((l) => l.startsWith('Lat ')), isTrue);

    final gps = make(StampLocationMode.coordinatesOnly, address: 'Station Rd').toLines();
    expect(gps, isNot(contains('Station Rd')));
    expect(gps.any((l) => l.startsWith('Lat ')), isTrue);
  });

  test('company, reference and inspector lines', () {
    final d = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: '',
      company: 'ABC Constructions',
      reference: 'JOB-42',
      inspector: 'R. Kumar',
      latitude: 1,
      longitude: 2,
    );
    final lines = d.toLines();
    expect(lines.first, 'ABC Constructions');
    expect(lines[1], startsWith('02 Jan 2026'));
    expect(lines[2], 'Ref: JOB-42   By: R. Kumar');
    final back = StampData.fromJson(d.toJson());
    expect(back.company, 'ABC Constructions');
    expect(back.reference, 'JOB-42');
    expect(back.inspector, 'R. Kumar');
  });

  test('stamp themes have distinct colours and labels', () {
    expect(StampTheme.classic.textArgb, isNot(StampTheme.light.textArgb));
    expect(StampTheme.bright.label, 'Bright');
    expect(const StampStyle().theme, StampTheme.classic);
    expect(
      const StampStyle().copyWith(theme: StampTheme.light).theme,
      StampTheme.light,
    );
  });

  test('plus codes are removed from place names', () {
    expect(AddressService.stripPlusCode('489X+796'), '');
    expect(AddressService.stripPlusCode('489X+796 Station Road'), 'Station Road');
    expect(AddressService.stripPlusCode('489X+796, Muzaffarpur'), 'Muzaffarpur');
    expect(AddressService.stripPlusCode('Station Road'), 'Station Road');
    expect(
      AddressService.joinParts(['489X+796', 'Muzaffarpur', 'Bihar', '843113']),
      'Muzaffarpur, Bihar, 843113',
    );
  });

  test('photo ids look right and are unique-ish', () {
    final ids = {for (var i = 0; i < 200; i++) PhotoId.generate()};
    expect(ids.length, 200);
    expect(ids.every(PhotoId.isValid), isTrue);
    expect(PhotoId.isValid('SS-00000000'), isFalse); // no 0/O
    expect(PhotoId.isValid('XX-ABCDEFGH'), isFalse);
  });

  test('site distance and radius', () {
    const site = SiteLocation(lat: 26.1189, lon: 85.3487, radius: 100);
    expect(site.distanceTo(26.1189, 85.3487), lessThan(1));
    // ~0.001 deg of latitude is about 111 m
    final d = site.distanceTo(26.1199, 85.3487);
    expect(d, inInclusiveRange(105, 118));
    expect(site.contains(26.1192, 85.3487), isTrue);
    expect(site.contains(26.1199, 85.3487), isFalse);
    final back = SiteLocation.fromJson(site.toJson());
    expect(back.radius, 100);
    expect(back.lat, 26.1189);
  });

  test('stamp shows site status, clock warning and photo id', () {
    StampData make({double? dist, bool clock = false}) => StampData(
          time: DateTime(2026, 1, 2, 3, 4, 5),
          memo: '',
          latitude: 1,
          longitude: 2,
          siteDistanceM: dist,
          siteRadiusM: dist == null ? null : 100,
          clockMismatch: clock,
          photoId: 'SS-ABCDEFGH',
        );
    final on = make(dist: 35).toLines();
    expect(on, contains('On site (35 m from site point)'));
    expect(on, contains('ID: SS-ABCDEFGH'));
    expect(make(dist: 35).siteStatus, 'on_site');

    final out = make(dist: 640).toLines();
    expect(out, contains('WARNING: 640 m from job site'));
    expect(make(dist: 1500).toLines(), contains('WARNING: 1.5 km from job site'));
    expect(make(dist: 640).siteStatus, 'outside');

    expect(make(clock: true).toLines(),
        contains('WARNING: device clock differs from GPS time'));
    expect(make().siteStatus, '');
    final back = StampData.fromJson(make(dist: 640, clock: true).toJson());
    expect(back.photoId, 'SS-ABCDEFGH');
    expect(back.clockMismatch, isTrue);
    expect(back.siteDistanceM, 640);
  });
}
