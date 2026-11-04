# Closed-test guide

## Message to send your testers (copy, edit the link, send on WhatsApp/email)

> Hi! I'm testing my app **SiteStamp**: a camera that prints date, time, place name and
> GPS on every photo, for site visits and field work.
> 1. Open this link on your Android phone and tap "Become a tester": [OPT-IN LINK]
> 2. Install SiteStamp from Google Play using the same Google account.
> 3. Please keep it installed for the next 14 days and use it a few times a week.
> 4. If anything looks wrong or confusing, tap the tune icon (top right) > **Send feedback**.
>    It opens an email with the app details already filled in. A screenshot helps a lot.
> Thank you, this really helps me launch it properly!
>
> नमस्ते! मैं अपना ऐप **SiteStamp** टेस्ट कर रहा हूँ: यह हर फ़ोटो पर तारीख़, समय, जगह का नाम और GPS छापता है।
> लिंक खोलकर "Become a tester" दबाएँ, ऐप Google Play से इंस्टॉल करें, और 14 दिन तक इंस्टॉल रखें।
> कोई दिक्कत हो तो ऊपर दाएँ कोने के आइकन > **Send feedback** दबाएँ। धन्यवाद!

## What to ask them to try (give 2-3 per person)
- Take 5 photos outdoors and 2 indoors; check the stamp and place name
- Change the language to Hindi in Settings
- Share a photo to WhatsApp (the caption has a map link)
- Open the photo list; select photos; export PDF/CSV (free users: watch-an-ad flow)
- Try the self-timer and the grid lines
- Rotate the phone, press Home, return: does the camera come back?
- Switch to the front camera and take one photo

Notes for testers:
- Banner and video ads show "Test Ad" while you are testing.
- Pro features can only be bought/tested by accounts you add under Play Console >
  Settings > License testing. Other testers will see the free version.

## Daily routine (about 10 minutes)
1. Play Console > Testing > Closed testing: check opted-in testers is still >= the number
   Play requires for your account (12 per current guidance; check your console).
2. Reply to every report within a day ("thanks, fixed in the next build" or "can you tell me...").
3. Check Quality > Android vitals for crashes/ANRs.
4. Keep a log (below).

## Feedback log (fill this in as you go: you will need it for the application)
| Date | Tester | What they reported | Severity | Fix / decision | Fixed in version |
|---|---|---|---|---|---|
| | | | | | |

## Timeline
| Day | To do |
|---|---|
| 1 | Send the message; confirm testers are opted in |
| 2-3 | Chase anyone who has not installed; replace non-responders |
| 4-10 | Collect feedback; fix real bugs; ship an update to the closed track (shows you act on feedback) |
| 11-14 | Keep testers engaged; do not let anyone opt out |
| 15 | Apply for production (Dashboard > Apply for production) |
