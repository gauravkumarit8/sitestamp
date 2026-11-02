# SiteStamp Teams - company subscriptions with seats

## 1. The idea in one paragraph
A company buys a subscription for N seats. The company admin invites employees. Each
invited employee signs in to the SiteStamp app, joins the company, and gets the Pro
experience (no ads, company details, projects, geofence, export). Photos upload to
the company's cloud space with a SERVER timestamp, and managers see everything in
a web dashboard. Individuals can still use the free app or buy Pro themselves.

## 2. People and roles
| Role | Can do |
|---|---|
| Owner | Everything, billing, delete company |
| Admin | Invite/remove members, create projects and sites, see all photos, export |
| Member (field user) | Capture, upload, see own photos and assigned projects |
| Viewer (later) | Read-only client/auditor access to selected projects |

## 3. How a company gets started (flow)
1. Admin visits the website, creates a company, starts a 14-day trial (e.g. 5 seats).
2. Admin invites members by email (or shares a join code/QR).
3. Member installs the app, signs in with the invited email (one-time code), is added.
4. App checks `my membership + company subscription` and unlocks team features.
5. Admin buys seats on the website (card/UPI). Seats can go up or down any time.
6. If a subscription lapses, members fall back to the free app (photos already
   uploaded stay available to the admin for a grace period, then per retention policy).

## 4. Seat rules
- active members <= seats purchased (enforced by the server, not just the app)
- inviting beyond the limit is blocked until the admin adds seats
- removing a member frees the seat immediately; their photos stay with the company
- one person can belong to one company at a time in v1

## 5. Architecture
```
Flutter app  --(HTTPS)-->  Supabase  : Auth (email OTP), Postgres (+RLS), Storage, Edge Functions
Admin web    --(HTTPS)-->  Supabase  : same project, admin screens (static site on GitHub Pages)
Website checkout --> Razorpay/Stripe --webhook--> Edge Function --> subscriptions table
```
Why Supabase over Firebase for this product:
- Seats, roles and projects are relational data; Postgres + row-level security fits well
- Edge functions can be pasted in the dashboard (no local tooling needed)
- Firebase Cloud Storage now requires a billing (Blaze) account since Feb 2026
Trade-offs: free Supabase projects pause when idle and are limited, so production
needs the paid plan (about $25/month at the time of writing - verify).

## 6. Data model (draft SQL in docs/teams/schema.sql)
organizations, memberships (role, status), invites, subscriptions (plan, seats,
status, period end), projects (name, site lat/lon/radius), photos (photo_id,
taken_at, uploaded_at, lat/lon/accuracy, address, memo, sha256, flags, storage_path).

## 7. Trust and tamper-evidence (what we can honestly claim)
- Photo is captured live inside the app (no gallery import)
- Phone-side checks: mock-GPS flag, clock-vs-GPS check, geofence
- On upload the server records its OWN time and the file's SHA-256; later edits to the
  file no longer match the stored fingerprint
- Large gap between taken_at and uploaded_at is flagged
- Do NOT claim "tamper-proof": a rooted/modified phone can still lie. Say
  "verifiable record with fraud checks".

## 8. Billing and Google Play rules
- Team plans are sold to businesses on the website. Google's Payments policy lists
  business-to-business transactions and cloud software/services for businesses among
  the cases that do not require Play Billing. The app must not push consumers from
  inside the app to outside payment; team members just sign in. CONFIRM the current
  policy text (or ask Play support) before launch.
- Individual Pro stays on Google Play Billing.
- Google has announced multi-quantity (group) subscriptions on Play; consider later.

## 9. Pricing hypotheses (test with pilots, set in INR)
| Plan | Price | Includes |
|---|---|---|
| Team | about Rs 149 / user / month (min 3 users; annual = 2 months free) | all Pro features, cloud upload, dashboard, PDF/CSV, geofence flags |
| Business | about Rs 299 / user / month | + checklists, attendance, enforced geofence, audit log, priority support |
| Enterprise | custom | + SSO, retention policy, data export, DPA, India data region |
Reference points seen: CompanyCam entry plan $79/month for 3 users + $29 per extra
user (annual); an Indian workforce app listing field tracking from Rs 180/user/month.

## 10. Cost estimate per user (very rough)
Assume 30 photos/day, 26 days, ~400 KB uploaded each = ~312 MB/user/month.
With 12 months retention that is ~3.7 GB per user; at about $0.021/GB-month that is
under $0.10 per user per month for storage, plus bandwidth. Payment fees and support
cost more than storage. Always compress uploads and set a retention policy.

## 11. Privacy and compliance
- Company = data fiduciary; employees = data principals (DPDP Act). Employment
  related processing can be a "legitimate use", but notice, security, retention and
  grievance handling still apply. Obligations for employers are phased in (around
  mid-2027 per one legal summary).
- Capture location only when a photo is taken (no background tracking) - say so.
- Provide: privacy notice for employees, data processing agreement for companies,
  export/delete on request, role-based access, audit log.
- Not legal advice; have a lawyer review before selling to companies.

## 12. Build phases (rough, assuming CI-only workflow)
| Phase | Scope | Time |
|---|---|---|
| T0 | Decisions, Supabase project, schema, auth settings | 2-3 days |
| T1 | App: sign-in, join company, entitlement from membership | ~1 week |
| T2 | App: upload queue (offline-first), server hash + time | ~1 week |
| T3 | Admin web: login, photos by project/user/map, members, export | 1-2 weeks |
| T4 | Website checkout + webhook + seat enforcement | ~1 week |
| T5 | Pilot with 3-5 companies, fixes, policy docs | 2+ weeks |

## 13. What I need from you to start T0
1. Confirm Supabase (or choose Firebase).
2. Create the project; share the Project URL and anon key (safe to ship in the app).
3. Choose the payment provider and start its business verification early.
4. Pick 3-5 pilot companies you can meet in person.
