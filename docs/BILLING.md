# Billing setup (Google Play)

The app code is in lib/services/billing_service.dart and lib/screens/pro_screen.dart.
Product IDs live in lib/config.dart and must match Play Console exactly:

| Product | ID | Type |
|---|---|---|
| Pro yearly | `sitestamp_pro_yearly` | Subscription |
| Pro lifetime | `sitestamp_pro_lifetime` | One-time product |

## Steps
1. Upload a build that includes the billing library (this version) to any track.
   Products cannot be created before such a build exists.
2. Play Console -> Monetize with Play -> Products.
   - Subscriptions -> Create subscription: ID `sitestamp_pro_yearly`, add a base
     plan (yearly, auto-renewing) with a price, then Activate.
   - One-time products -> Create: ID `sitestamp_pro_lifetime`, set a price, Activate.
3. Set up your payments (merchant) profile if Console asks.
4. Play Console -> Settings -> License testing: add the Gmail accounts you will
   test with. Testers are never charged and subscriptions renew quickly.
5. Upload this version to the Internal testing track, join via the opt-in link on
   a phone signed in with a license-tester account, and install from Play.
   Sideloaded APKs cannot load products.
6. In the app: settings (tune icon) -> Upgrade to SiteStamp Pro. You should see
   both prices. Buy one, confirm Pro features unlock (no "Made with SiteStamp"
   line, address on photos).
7. Test "Restore purchases" after clearing app data.

## Notes
- Checks are client-side only. A rooted device can bypass them. Server-side
  verification is a later upgrade if piracy becomes a problem.
- A confirmed purchase is cached; if Play does not re-confirm it for 14 days the
  app falls back to the free plan (covers cancelled/expired subscriptions).
- Show prices/terms clearly (the Pro screen does) and keep the privacy policy
  mentioning purchases (done in the 30 Oct 2026 version).
- Data safety form: check whether purchase history needs declaring; answer per
  Play Console's current wording.
