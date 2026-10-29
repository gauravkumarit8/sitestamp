# Changelog

## v0.5.0
- Tap to focus (with focus ring) and exposure point
- Pinch to zoom (capped at 8x) with zoom badge
- Optional rule-of-thirds grid (settings)
- Shutter haptic + brief flash feedback
- Hindi Play Store listing (docs/store/listing_hi.md)
- Phone test checklist (docs/TESTING.md)

## v0.4.0
- Free/Pro structure (no billing yet): lib/services/entitlements.dart is the single place that decides what is free
- Free plan: "Made with SiteStamp" line on photos, 3 recent-note chips, no address
- Pro plan: no branding line, address on photos, 10 recent-note chips
- Debug builds (CI APK) get a "Pro (testing only)" switch in settings; release builds stay free until billing is added

## v0.3.0
- Signed release workflow, privacy policy, store listing, feature graphic

## v0.2.0
- Street address on the stamp (background reverse geocoding, toggle in settings)
- Memo presets: recent notes + defaults as tap-to-fill chips, clear button
- Settings sheet (address on/off)
- App icon (adaptive + legacy) and 512 px Play Store icon in docs/store
- GPS pill no longer overflows on narrow screens
- Setup script now also adds geocoding + shared_preferences to pubspec.yaml

## v0.1.2
- compileSdk 37 for permission_handler_android; platform config runs in CI

## v0.1.1
- GitHub Actions: bootstrap + build (analyze, test, debug APK)

## v0.1.0
- Camera, live GPS pill, stamp pipeline, save to gallery album
