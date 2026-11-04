import 'package:flutter_test/flutter_test.dart';
import 'package:sitestamp/l10n/app_language.dart';
import 'package:sitestamp/l10n/hindi.dart';

void main() {
  tearDown(() => AppLanguage.instance.set('en'));

  test('English returns the text unchanged', () {
    AppLanguage.instance.set('en');
    expect(tr('Cancel'), 'Cancel');
    expect(tr('Something not in the dictionary'), 'Something not in the dictionary');
  });

  test('Hindi returns the translation and falls back to English', () {
    AppLanguage.instance.set('hi');
    expect(tr('Cancel'), kHindi['Cancel']);
    expect(tr('Cancel'), isNot('Cancel'));
    expect(tr('Not translated yet'), 'Not translated yet');
  });

  test('language switch notifies listeners and ignores unknown codes', () {
    var calls = 0;
    void listener() => calls++;
    AppLanguage.instance.addListener(listener);
    AppLanguage.instance.set('hi');
    AppLanguage.instance.set('hi'); // no change, no notification
    AppLanguage.instance.set('zz'); // unknown -> English
    AppLanguage.instance.removeListener(listener);
    expect(calls, 2);
    expect(AppLanguage.instance.code, 'en');
  });

  test('every Hindi entry is real text', () {
    expect(kHindi.length, greaterThan(100));
    kHindi.forEach((en, hi) {
      expect(hi.trim(), isNotEmpty, reason: en);
      expect(hi, isNot(en), reason: en);
    });
  });
}
