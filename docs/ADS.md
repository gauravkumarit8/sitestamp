# Ads (Google AdMob) - setup and rules

The app ships with Google's public TEST ad ids, so you will see "Test Ad" banners
and earn nothing until you replace them.

## Where ads appear
- Banner: bottom of the Photos screen (free users only).
- Rewarded ad: optional, lets a free user export one PDF/CSV.
- NEVER on the camera screen, never over the shutter, never as a full-screen
  interstitial after a photo. Pro users see no ads at all.
- Master switch: `kAdsEnabled` in lib/config.dart.

## Steps to go live
1. Create an AdMob account (admob.google.com) and add the Android app
   `com.grvthakur.sitestamp`.
2. Copy the **App ID** (looks like ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY) into
   android/app/src/main/AndroidManifest.xml (`com.google.android.gms.ads.APPLICATION_ID`).
3. Create two ad units and put their ids in lib/config.dart:
   - Banner -> `kAdMobBannerUnitId`
   - Rewarded -> `kAdMobRewardedUnitId`
4. AdMob > Privacy & messaging: create and publish a GDPR consent message
   (needed for EEA/UK users; without it no consent form is shown).
5. app-ads.txt: add your AdMob publisher line to the app-ads.txt file at the root of
   the developer website listed on your Play listing (your GitHub Pages site already has one).
6. Never tap your own live ads. Use a test device in AdMob while developing.

## Play Console changes (required)
- App content > Ads: answer **Yes, my app contains ads**.
- App content > Advertising ID: declare that the app uses it (for advertising).
- Data safety: declare the data the Mobile Ads SDK collects (device or other IDs,
  approximate location/IP, diagnostics) per Google's AdMob data-disclosure guide.
- Update the store listing text (it must not say "no ads") and the privacy policy
  (done in the 31 Oct 2026 version).

## Expectations
Banner and rewarded revenue per user is small. Ads mostly make sense once you have
many daily users; their main job here is to make "Pro = no ads" a clear benefit.
