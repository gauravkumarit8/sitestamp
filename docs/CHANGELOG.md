# Changelog

## v0.9.2
- Test fix: entitlements test now expects the free place name and checks Pro-only flags
- Lint/analyze cleanup: remove unneeded `!`, unneeded cross_file imports, add braces

## v0.9.1
- FIX: camera screen collapsed into a strip at the top (Stack shrank to the top bar's height). Stack now fills the screen and the top bar is pinned with Positioned
- Place name on the photo: new setting "Name / Name + GPS / GPS only" (default: Name). If no name is available the photo falls back to GPS coordinates
- Place name is now FREE for everyone (Entitlements.canShowAddress); Pro value is projects, stamp style, export, unlimited list, no branding
- Resolved place name is shown under the GPS pill on the camera screen
- Pro screen and settings text updated for the new split

## v0.9.0
- FIX: top bar (GPS pill, flash, switch, settings) was vertically centred on screen and overlapped the shutter when the keyboard opened; it is now pinned to the top
- FIX: share_plus ^13.3.1 (11/12 conflicted with geolocator 14 over win32)
- In-app photo list: every photo is also kept as an app-private copy; grid with project filter, multi-select, share, remove-from-app (gallery copies are never deleted)
- Free plan keeps the latest 50 photos in the list; Pro keeps everything
- Export a project or selection as PDF report (newest 60 photos, 4 per page) or CSV spreadsheet (Pro)
- Stamp preview in settings shows position/size and the free/Pro difference
- Last-photo thumbnail now loads at startup and opens the list when empty
- Snackbar shortened so it does not cover the shutter for long

## v0.8.0
- Last-photo thumbnail next to the shutter; tap for a full-screen preview
- Share button (WhatsApp, email, etc.) sends the stamped photo with a caption: time, project, address, coordinates, Google Maps link and note
- Sharing is free on every plan
- New package: share_plus (added by tool/apply_platform_config.ps1)

## v0.7.0
- Projects (Pro): pick a project and photos save to the gallery album "SiteStamp - <project>"; the project name is also printed on the stamp
- Stamp style (Pro): position (bottom/top) and size (small/medium/large)
- Free plan keeps the default SiteStamp album and the standard stamp
- Tests for album naming, project line and stamp style

## v0.6.0
- Google Play Billing: Pro yearly (subscription) + Pro lifetime (one-time)
- Pro screen with prices, buy and restore; purchases cached with a 14-day grace
- Entitlements tests; docs/BILLING.md setup guide
- Privacy policy: Purchases section (30 Oct 2026)

## v0.5.2
- Fix release signing patch (imports instead of java.util)

## v0.5.1
- Privacy policy link + Contact support in the settings sheet (url_launcher)
- Contact details and the live privacy policy URL filled in docs
- Landing page and privacy policy moved to the gauravkumarit8.github.io repo
- Manifest: allow https/mailto link handling (Android 11+ package visibility)

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
