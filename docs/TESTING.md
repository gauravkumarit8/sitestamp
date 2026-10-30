# Phone test checklist

Install `app-debug.apk` from the latest Build run (artifact `sitestamp-debug-apk`).

Phone model + Android version: ______________________

| # | Check | Result / notes |
|---|---|---|
| 1 | Camera + location prompts appear, camera opens | |
| 2 | GPS pill: orange then green (note seconds taken) | |
| 3 | Free photo upright in gallery? Stamp readable? Dim "Made with SiteStamp" line? | |
| 4 | "SiteStamp" album exists in gallery | |
| 5 | Front camera photo upright / not oddly mirrored | |
| 6 | Pro (testing only) ON: address appears, branding line gone | |
| 7 | Memo chips: tap fills, x removes, clear button works | |
| 8 | Tap to focus: yellow ring appears, no crash | |
| 9 | Pinch zoom works, zoom badge shows, resets after switching camera | |
| 10 | Grid lines toggle in settings | |
| 11 | Flash + switch camera buttons | |
| 12 | Home, wait, return: preview comes back | |
| 13 | Save time after shutter (seconds) | |
| 14 | Deny location once: what happens? | |
| 15 | App icon looks right on home screen | |
| 16 | 20 photos in a row: any slowdown or crash? | |
| 17 | Free plan: tapping the album chip opens the Pro screen | |
| 18 | Pro ON: create a project, take a photo; album "SiteStamp - <project>" appears; "Project:" line on the stamp | |
| 19 | Pro ON: stamp position Top and size Large change the photo | |
| 20 | Switch project back to Default; next photo goes to "SiteStamp" album | |
| 21 | Thumbnail appears after a photo; tap opens the preview; pinch zoom works there | |
| 22 | Share to WhatsApp: photo arrives with caption (time, address, coordinates, Maps link) and the Maps link opens the right place | |

## How to report a problem
Send: the row number, what you expected, what happened, and a screenshot. For a
crash, also send the Build run link and, if you can, `adb logcat` output.
