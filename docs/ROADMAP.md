# SiteStamp roadmap and priorities

Scoring: value to users/companies, effort (S = days, M = 1-2 weeks, L = a month+),
and whether it needs a server.

## P0 - Launch (you)
Green build, phone test (docs/TESTING.md rows 17-40), AdMob ids, billing products,
Play listing + Data safety + Ads declaration, 12-tester closed test.

## P1 - Trust pack (no server)  <- implemented in v1.1.0
| Item | Why | Effort |
|---|---|---|
| Job-site geofence per project (Pro) | Proves "I was at the site" | S |
| Clock check (phone time vs GPS time) | Catches changed device time | S |
| Sticky fake-GPS flag (10 min) | One mock fix flags the next photos too | S |
| Photo ID (SS-XXXXXXXX) printed on photo | Reference in reports and disputes | S |
| SHA-256 fingerprint stored + exported | Detect later edits to a photo | S |

## P2 - Teams foundation (needs a server) - see docs/TEAMS_PLAN.md
Company account, seats, invites, cloud upload, server timestamp, admin web dashboard,
web checkout for seats. This is what companies actually pay for.

## P3 - Reach
- Hindi interface - M  (DONE in v1.3.0; other Indian languages: add a map like lib/l10n/hindi.dart)
- Landscape + tablet support - S/M
- Inspection checklists / templates - M  (DONE in v1.2.0, Pro)
- Photo annotations (arrow, circle, text) - M
- Attendance mode (selfie clock in/out, geofenced) - M

## P4 - Later
- iOS app (Mac CI runner + Apple developer account) - L
- Video with stamp - L
- Vertical templates (PM Surya Ghar solar photo set, government-works before/after)
- Integrations (Google Sheets, WhatsApp Business, Tally/Zoho exports)

## Technical debt
- Replace flutter_image_compress / native_exif (old Kotlin Gradle plugin warning)
- Server-side purchase verification
- Widget tests; crash reporting; dependency upgrades
