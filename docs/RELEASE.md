# Release guide (Play Store)

## One-time: create the upload keystore (keep it forever)
1. Install a JDK (provides `keytool`):
   `winget install EclipseAdoptium.Temurin.17.JDK`  (then reopen PowerShell)
2. Create the keystore:
   `keytool -genkeypair -v -keystore "$HOME\sitestamp-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
3. BACK UP `sitestamp-upload.jks` and both passwords somewhere safe (not in git).
4. Copy the keystore as base64:
   `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\sitestamp-upload.jks")) | Set-Clipboard`
5. GitHub repo -> Settings -> Secrets and variables -> Actions -> New repository secret:
   - ANDROID_KEYSTORE_BASE64  (paste)
   - ANDROID_KEYSTORE_PASSWORD
   - ANDROID_KEY_ALIAS  (upload)
   - ANDROID_KEY_PASSWORD

## Each release
1. Actions -> "Release (signed AAB + APK)" -> Run workflow.
2. Download `sitestamp-release-apk`, install on a phone and test (release builds
   use R8 shrinking and can behave differently from debug).
3. Download `sitestamp-release-aab` and upload it in Play Console.
   Version code = the workflow run number (always increasing).
4. Use Play App Signing when Play Console offers it.

## Privacy policy and landing page
These live in the separate repo gauravkumarit8/gauravkumarit8.github.io under /sitestamp/.
Live URLs:
- Landing page: https://gauravkumarit8.github.io/sitestamp/
- Privacy policy: https://gauravkumarit8.github.io/sitestamp/privacy-policy.html
Do not enable GitHub Pages on the sitestamp repo itself (it would clash with the /sitestamp/ path).
docs/privacy-policy.md here is only a reference copy; keep the two in sync.
