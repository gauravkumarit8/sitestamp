import 'package:flutter_test/flutter_test.dart';
import 'package:sitestamp/config.dart';
import 'package:sitestamp/services/feedback.dart';

void main() {
  test('feedback body has app details and no coordinates', () {
    final body = buildFeedbackBody(
      androidVersion: 'Android 14',
      isPro: false,
      language: 'hi',
      photoSize: 'standard',
      gps: '±12 m',
      placeName: 'addressFirst',
    );
    expect(body, contains('App: SiteStamp $kAppVersion (build $kBuildNumber)'));
    expect(body, contains('Android: Android 14'));
    expect(body, contains('Plan: Free'));
    expect(body, contains('Language: hi'));
    expect(body, contains('GPS: ±12 m'));
    expect(body.toLowerCase(), isNot(contains('lat ')));
    expect(
      buildFeedbackBody(
        androidVersion: 'x',
        isPro: true,
        language: 'en',
        photoSize: 'large',
        gps: 'no fresh fix',
        placeName: 'off',
      ),
      contains('Plan: Pro'),
    );
  });

  test('mailto uses %20 for spaces and carries subject and body', () {
    final uri = feedbackUri(
      to: 'a@b.com',
      subject: 'SiteStamp feedback 1.3.1',
      body: 'Line one\nLine two',
    );
    final s = uri.toString();
    expect(s.startsWith('mailto:a@b.com?'), isTrue);
    expect(s.contains('+'), isFalse);
    expect(s, contains('subject=SiteStamp%20feedback%201.3.1'));
    expect(s, contains('Line%20one%0ALine%20two'));
  });

  test('version constants look sane', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(kAppVersion), isTrue);
    expect(kBuildNumber, isNotEmpty);
  });
}
