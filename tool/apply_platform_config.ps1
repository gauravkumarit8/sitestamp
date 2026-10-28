# Idempotent platform tweaks that cannot be shipped as plain file overlays.
# Works on Windows and Linux (CI) PowerShell.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# --- Android: camera/geolocator plugins need minSdk 24 ---
foreach ($f in @('android/app/build.gradle.kts', 'android/app/build.gradle')) {
    if (Test-Path $f) {
        $full = (Resolve-Path $f).Path
        $c = [System.IO.File]::ReadAllText($full)
        $n = $c -replace 'flutter\.minSdkVersion', '24'
        if ($n -ne $c) {
            [System.IO.File]::WriteAllText($full, $n, $utf8)
            Write-Host "minSdk set to 24 in $f"
        } else {
            Write-Host "minSdk already customised in $f (check it is >= 24)"
        }
    }
}

# --- iOS: usage descriptions (iOS build needs a Mac; added now for later) ---
$plist = 'ios/Runner/Info.plist'
if (Test-Path $plist) {
    $full = (Resolve-Path $plist).Path
    $c = [System.IO.File]::ReadAllText($full)
    if ($c -notmatch 'NSCameraUsageDescription') {
        $add = @"
	<key>NSCameraUsageDescription</key>
	<string>SiteStamp needs the camera to take job photos.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>SiteStamp stamps your location onto each photo.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>SiteStamp saves stamped photos to your library.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>SiteStamp saves stamped photos to the SiteStamp album.</string>

"@
        $idx = $c.LastIndexOf('</dict>')
        $c = $c.Insert($idx, $add)
        [System.IO.File]::WriteAllText($full, $c, $utf8)
        Write-Host 'iOS usage descriptions added'
    } else {
        Write-Host 'iOS usage descriptions already present'
    }
}
