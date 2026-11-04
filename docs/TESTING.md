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

| 23 | Top bar (GPS pill, flash, switch, settings) is at the TOP of the screen; keyboard open does not overlap the shutter | |
| 24 | Thumbnail opens the photo; "All photos" opens the grid; filter chips by project | |
| 25 | Long-press selects photos; Share (2+ photos), Remove from app (gallery copy stays) | |
| 26 | Pro ON: Export PDF opens the share sheet; PDF has photos + captions; CSV opens in Excel/Sheets | |
| 27 | Free: Export shows lock and opens the Pro screen | |
| 28 | Settings: stamp preview changes with position and size | |

| 29 | Camera screen fills the whole screen: preview behind, top bar at top, note field + shutter at bottom | |
| 30 | Settings: Name / Name + GPS / GPS only changes the stamp preview; place name appears under the GPS pill after a few seconds (needs internet) | |
| 31 | Photo shows the place name instead of Lat/Lon (and falls back to Lat/Lon in airplane mode) | |

| 32 | Place name no longer shows a Plus Code like 489X+796 | |
| 33 | Free: banner (labelled Test Ad) at the bottom of the Photos screen only; none on the camera screen; none after enabling Pro | |
| 34 | Free: Export asks "Watch ad / Upgrade"; Watch ad then export works once | |
| 35 | Pro: Company and job details saved; appear on the next photo; themes change the stamp colours | |
| 36 | Pro: select 2 photos, tap compare icon: Before/After image is built, saved to gallery, share sheet opens | |
| 37 | FRONT CAMERA, phone held upright: photo is upright (not sideways) | |

| 38 | Pro: project > location icon > Set here; chip shows "On site"; walk 100+ m away and it shows distance | |
| 39 | Photo taken outside the site prints "WARNING: ... from job site"; inside prints "On site" | |
| 40 | Every photo has "ID: SS-XXXXXXXX"; CSV export has photo_id and sha256 | |
| 41 | Change phone date/time manually: pill/photo show clock warning (needs a GPS fix) | |

| 42 | Pro: open Checklist chip, choose "Rooftop solar installation"; chip shows "Step 1/8" | |
| 43 | Take a photo: stamp prints "Step 1/8: ..."; chip moves to step 2; steps show green ticks | |
| 44 | Tap step 5 to shoot it out of order; photo is tagged step 5 | |
| 45 | New checklist from text works; Start over resets ticks; CSV has checklist_step | |
| 46 | Free user: Checklist chip shows a lock and opens the Pro screen | |

| 47 | First launch shows 3 welcome screens; Skip and Get started both go to permissions; not shown again | |
| 48 | Settings: switch to हिन्दी; labels, chips, dialogs and Pro screen change to Hindi; switch back works | |
| 49 | Phone set to Hindi, fresh install: app starts in Hindi | |
| 50 | Settings: 12-hour, Deg-min-sec, Feet change the preview and the next photo's stamp | |
| 51 | Photo size Small/Standard: photos save faster/smaller; Large asks for Pro on free | |
| 52 | Timer 3 s and 10 s: countdown shows, photo is taken at 0; tapping the shutter during countdown cancels | |

| 53 | Settings > Send feedback opens the email app; subject/body readable (no + signs); includes app version, build, Android, plan, GPS state; no coordinates | |

## How to report a problem
Send: the row number, what you expected, what happened, and a screenshot. For a
crash, also send the Build run link and, if you can, `adb logcat` output.
