import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitestamp/services/entitlements.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int daysAgoMs(int days) =>
      DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

  test('free by default', () async {
    SharedPreferences.setMockInitialValues({});
    final e = await Entitlements.load();
    expect(e.isPro, isFalse);
    expect(e.showBranding, isTrue);
    expect(e.canShowAddress, isFalse);
    expect(e.maxRecentMemos, 3);
  });

  test('recently confirmed purchase is Pro', () async {
    SharedPreferences.setMockInitialValues({
      'purchased_pro': true,
      'purchased_pro_confirmed_ms': daysAgoMs(2),
    });
    final e = await Entitlements.load();
    expect(e.isPro, isTrue);
    expect(e.showBranding, isFalse);
    expect(e.maxRecentMemos, 10);
  });

  test('purchase not re-confirmed for 20 days falls back to free', () async {
    SharedPreferences.setMockInitialValues({
      'purchased_pro': true,
      'purchased_pro_confirmed_ms': daysAgoMs(20),
    });
    final e = await Entitlements.load();
    expect(e.isPro, isFalse);
  });

  test('applyPurchase toggles Pro', () async {
    SharedPreferences.setMockInitialValues({});
    final e = await Entitlements.load();
    await e.applyPurchase(pro: true);
    expect(e.isPro, isTrue);
    await e.applyPurchase(pro: false);
    expect(e.isPro, isFalse);
  });
}
