# SiteStamp - MVP spec (v0.1)

Audience: solo field workers and small service teams who need photo proof of
where and when a job was done.

## Capture pipeline
1. Snapshot latest fresh GPS fix + time at the moment of the tap.
2. `takePicture()` -> raw temp file.
3. `flutter_image_compress`: downscale to ~1920 px, rotate pixels upright, strip EXIF.
4. Draw stamp (time, lat/lon, altitude, accuracy, memo) with `dart:ui`.
5. Encode JPEG, write GPS EXIF, `Gal.putImage` into the "SiteStamp" album.
6. Delete every temp file.

## Rules
- Portrait only in v0.1 (orientation safety).
- Never read full-size images into memory; always downscale first.
- GPS older than 30 s is treated as unavailable and is NOT stamped.
- Mock-location fixes are flagged on the pill and on the photo.

## Test checklist (real devices)
- [ ] Photo upright in Samsung Gallery, Google Photos, Files app
- [ ] Back and front camera both upright; front not unexpectedly mirrored
- [ ] Stamp readable on bright and dark scenes
- [ ] Location off / permission denied handled
- [ ] Memory stable after 30 consecutive photos on a budget phone
- [ ] Leaving the screen stops GPS and camera
