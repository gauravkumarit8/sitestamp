# Free vs Pro (working proposal)

Edit `lib/services/entitlements.dart` to change the split. Everything below is a
starting hypothesis to test, not a fact about the market.

| | Free | Pro |
|---|---|---|
| Date, time, GPS, altitude, accuracy on photo | yes | yes |
| Note on photo | yes | yes |
| Mock-location warning | yes | yes |
| Front/back camera, flash | yes | yes |
| "Made with SiteStamp" line | yes | no |
| Recent-note chips | 3 | 10 |
| Place name / street address on photo | yes | yes |
| Projects (one gallery album per job) | no | yes |
| Stamp position and size | no | yes |
| Photos kept in the in-app list | latest 50 | unlimited |
| PDF / CSV export | no | yes |

Later Pro candidates: PDF/CSV export, cloud backup, shared team projects.

## Price hypotheses (set per-country prices in Play Console)
Competitor apps seen during research used a mix of weekly, monthly, yearly,
lifetime and one-time pricing, roughly from a few dollars one-time up to
about $15 to $20 for a yearly or lifetime plan, and about $50 per year for
team-oriented tools.

Start with two products and compare conversion:
- `sitestamp_pro_yearly`   - subscription, low price
- `sitestamp_pro_lifetime` - one-time purchase, around 2 to 3 times the yearly price

Avoid weekly plans at first; they attract refund and review problems.

## Before billing can be added
1. App uploaded to a Play Console test track (internal testing is enough).
2. Products created in Play Console (Monetize > Products).
3. Merchant/payments profile set up.
Then we add the `in_app_purchase` package and call `Entitlements.applyPurchase`.
