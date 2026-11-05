import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitestamp/models/site_location.dart';
import 'package:sitestamp/models/stamp_data.dart';
import 'package:sitestamp/screens/annotate_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markAnnotated keeps every field and sets the flag', () {
    final d = StampData(
      time: DateTime(2026, 1, 2, 3, 4, 5),
      memo: 'Gate 3',
      latitude: 1.5,
      longitude: 2.5,
      altitude: 10,
      accuracy: 5,
      address: 'MG Road',
      project: 'Tower A',
      photoId: 'SS-ABCDEFGH',
      step: 'Step 1/3: One',
      company: 'ABC',
      reference: 'J-1',
      inspector: 'RK',
      siteDistanceM: 35,
      siteRadiusM: 100,
    );
    expect(d.annotated, isFalse);
    final a = d.markAnnotated();
    expect(a.annotated, isTrue);
    expect(a.memo, 'Gate 3');
    expect(a.project, 'Tower A');
    expect(a.photoId, 'SS-ABCDEFGH');
    expect(a.siteDistanceM, 35);
    expect(a.toLines(), d.toLines());
    expect(StampData.fromJson(a.toJson()).annotated, isTrue);
    expect(StampData.fromJson(d.toJson()).annotated, isFalse);
  });

  test('drawing every tool does not throw', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
    paintAnnotations(
      canvas,
      [
        AnnotationShape(AnnotationTool.pen, Colors.red, [
          const Offset(10, 10),
          const Offset(50, 60),
          const Offset(90, 20),
        ]),
        AnnotationShape(AnnotationTool.pen, Colors.red, [const Offset(5, 5)]),
        AnnotationShape(AnnotationTool.arrow, Colors.yellow, [
          const Offset(20, 20),
          const Offset(200, 120),
        ]),
        AnnotationShape(AnnotationTool.arrow, Colors.yellow, [
          const Offset(20, 20),
          const Offset(20, 20), // zero length, skipped
        ]),
        AnnotationShape(AnnotationTool.circle, Colors.white, [
          const Offset(100, 100),
          const Offset(250, 220),
        ]),
      ],
      6,
    );
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
    picture.dispose();
  });

  test('suggestProject offers the job site you are standing in', () {
    const a = SiteLocation(lat: 26.1000, lon: 85.3000, radius: 100);
    const b = SiteLocation(lat: 26.1100, lon: 85.3000, radius: 200); // ~1.1 km away
    const c = SiteLocation(lat: 26.1004, lon: 85.3000, radius: 200); // overlaps a
    final sites = {'A': a, 'B': b, 'C': c};
    SiteLocation? siteFor(String n) => sites[n];

    // standing at A while project B is active -> suggest A
    expect(
      suggestProject(
        projects: ['A', 'B'],
        siteFor: siteFor,
        current: 'B',
        lat: 26.1000,
        lon: 85.3000,
      ),
      'A',
    );
    // already on A -> nothing to suggest
    expect(
      suggestProject(
        projects: ['A', 'B'],
        siteFor: siteFor,
        current: 'A',
        lat: 26.1000,
        lon: 85.3000,
      ),
      isNull,
    );
    // overlapping sites: current project C also contains you -> no suggestion
    expect(
      suggestProject(
        projects: ['A', 'C'],
        siteFor: siteFor,
        current: 'C',
        lat: 26.1000,
        lon: 85.3000,
      ),
      isNull,
    );
    // no project selected, standing at A -> suggest A
    expect(
      suggestProject(
        projects: ['A', 'B'],
        siteFor: siteFor,
        current: '',
        lat: 26.1000,
        lon: 85.3000,
      ),
      'A',
    );
    // far from every site
    expect(
      suggestProject(
        projects: ['A', 'B'],
        siteFor: siteFor,
        current: '',
        lat: 27.0,
        lon: 86.0,
      ),
      isNull,
    );
    // a project without a site is ignored
    expect(
      suggestProject(
        projects: ['Z'],
        siteFor: siteFor,
        current: '',
        lat: 26.1,
        lon: 85.3,
      ),
      isNull,
    );
  });
}
