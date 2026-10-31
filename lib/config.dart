/// App-wide constants.
const String kPrivacyPolicyUrl =
    'https://gauravkumarit8.github.io/sitestamp/privacy-policy.html';
const String kSupportEmail = 'gaurav954624@gmail.com';

/// Google Play product IDs (must match Play Console exactly).
const String kProYearlyId = 'sitestamp_pro_yearly';
const String kProLifetimeId = 'sitestamp_pro_lifetime';
const List<String> kProProductOrder = [kProYearlyId, kProLifetimeId];

/// ---- Ads (Google AdMob) ----
/// Master switch. Ads are never shown to Pro users and never on the camera screen.
const bool kAdsEnabled = true;

/// Google's public TEST ad units. They show "Test Ad" labels and earn nothing.
/// Replace with your own AdMob ad unit ids before a public release
/// (see docs/ADS.md). The AdMob *app* id lives in AndroidManifest.xml.
const String kAdMobBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
const String kAdMobRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';
