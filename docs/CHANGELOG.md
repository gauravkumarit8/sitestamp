# Changelog

## v1.3.1 - Feedback and version info
- Settings > Send feedback: opens your email app with app version, build, Android version, plan, language, photo size and GPS state already filled in (no coordinates)
- Email subject/body links now use %20 (no "+" showing in mail apps)
- Version name now comes from kAppVersion in lib/config.dart; build number from the CI run (shown in feedback emails)
- docs/TESTER_GUIDE.md (message for closed testers) and docs/PRODUCTION_ACCESS.md (answer templates)

## v1.3.0
- Hindi interface (हिन्दी): switch in Settings or on the first screen; follows the phone language on first launch. The text printed on photos stays English by design
- Stamp format options: 12 or 24-hour time, decimal or degrees-minutes-seconds coordinates, metres or feet
- Photo size: Small (1280), Standard (1920), Large (2400, Pro)
- Self-timer: 3 or 10 seconds with an on-screen countdown (tap the shutter to cancel)
- Welcome screens on first launch (3 pages, with language choice)

## v1.2.2
- FIX: AGP 9 rejects proguard-android.txt; the release script now uses proguard-android-optimize.txt

## v1.2.1 - Release crash fix
- FIX: release builds crashed at startup ("Failed to create an instance of androidx.work.impl.WorkDatabase"). AGP 9's stricter R8 breaks WorkManager/Room pulled in by the ads SDK. Added android/app/proguard-rules.pro (wired in by tool/apply_signing_config.ps1) and the release workflow now also builds with --no-shrink

## v1.2.0 - Checklists
- Photo checklists (Pro): required photos for a job. Built-in examples (rooftop solar, civil works, maintenance visit, delivery proof) or create your own (one step per line)
- A chip shows the next step; tap to pick any step. Each photo is tagged "Step 3/8: ..." on the stamp and ticks the step off. Progress is kept per project; "Start over" resets it
- CSV export gets a checklist_step column; PDF captions and share text include the step

## v1.1.1
- FIX: google_mobile_ads ^9.1.0 (5.x fails on Gradle 9: unknown property 'all'); setup script upgrades an existing constraint

## v1.1.0 - Trust pack
- Job-site geofence per project (Pro): set the site from your current position with a 50-500 m radius; chip shows "On site" / distance; the photo prints "On site" or "WARNING: x m from job site"
- Clock check: warns when the phone time differs from GPS time by over 5 minutes
- Sticky fake-GPS flag: one mock fix flags photos for the next 10 minutes
- Photo ID (SS-XXXXXXXX) printed on every photo; SHA-256 fingerprint of each saved photo kept in the app and exported
- CSV: photo_id, sha256, clock_check, site_status, site_distance_m columns
- docs: ROADMAP.md, TEAMS_PLAN.md, teams/schema.sql (draft)

## v1.0.0
- Pro value: company name, job/reference no. and inspector on every photo; stamp themes (Classic/Bright/Light); Before/After comparison images from two photos; ad-free
- Ads for free users (Google AdMob): small banner on the Photos screen only, plus an optional rewarded ad to export once. NEVER on the camera screen. Pro removes all ads. Test ad ids until you replace them (docs/ADS.md)
- Consent (UMP) flow for EEA/UK users
- FIX: Plus Codes like "489X+796" are no longer printed as the place name
- CSV export has company/reference/inspector columns

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
