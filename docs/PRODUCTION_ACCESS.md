# Production access: answer templates

After the closed test, Play Console > Dashboard > **Apply for production** asks about your
test, your app and its readiness. Reports say there are about 10 questions (a few
multiple choice) and roughly 300 characters per free-text answer. Read the exact wording in your
console; this file is a starting point.

Rules that matter:
1. Be specific and TRUE. Use real numbers from your own test. Do not invent testers,
   feedback or fixes. Do not pay for fake reviews.
2. Show you acted on feedback: ship at least one real update during the test.
3. Keep the required number of testers opted in for 14 continuous days.
4. Typical reasons for rejection: vague answers, no visible updates, testers who never opened the app.

## Draft answers (replace [brackets] with your facts; keep each under 300 characters)

**How did you recruit your testers?**
I invited [N] people I know: [contractors / installers / colleagues / friends] by WhatsApp and email. Each joined with the opt-in link, installed from Play and kept the app for the full 14 days.

**How easy was it to recruit testers?** (multiple choice) Pick the honest option.

**Describe the engagement and feedback you received, and how you collected it.**
Testers used it on real jobs [N] times a week. Feedback came through the in-app Send feedback button (app details prefilled), WhatsApp and calls. I logged [N] reports; main issues: [1], [2], [3].

**Who is the intended audience?**
Field workers, site inspectors, contractors, solar installers, surveyors and delivery staff who must show where and when a job was done. Adults, mostly in India; English and Hindi.

**How does your app provide value to users?**
It prints date, time, place name and GPS on each photo at capture, with job notes, project albums, checklists, WhatsApp sharing with a map link and PDF/CSV reports, replacing manual timestamp apps and messy photo threads.

**How many installs do you expect in the first year?** (multiple choice) Choose a realistic range.

**What changes did you make based on testing?**
Shipped [versions] during the test: [fix 1], [fix 2], [new feature from a request]. Example: [tester] reported [problem]; fixed in version [x] and confirmed by them.

**Why is your app ready for production?**
Core flows work on [N] phone models; Android vitals show [no/low] crashes; privacy policy, Data safety, ads and billing are set up; the release build is signed and tested.

## Facts you can use from the project history
See docs/CHANGELOG.md. Only list changes that were actually uploaded to the closed track
during your test, with the real dates.
