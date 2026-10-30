# Idempotent platform tweaks that cannot be shipped as plain file overlays.
# Works on Windows PowerShell and Linux pwsh (CI).
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$MinSdk = 24
$CompileSdk = 37   # permission_handler_android requires >= 37

function Update-File([string]$path, [scriptblock]$transform) {
    $full = (Resolve-Path $path).Path
    $old = [System.IO.File]::ReadAllText($full)
    $new = & $transform $old
    if ($new -ne $old) {
        [System.IO.File]::WriteAllText($full, $new, $utf8)
        Write-Host "Updated $path"
    } else {
        Write-Host "No change needed in $path"
    }
}

# --- pubspec: make sure required packages are present (idempotent) ---
if (Test-Path 'pubspec.yaml') {
    Update-File 'pubspec.yaml' {
        param($c)
        $deps = @(
            @('geocoding', '^4.0.0'),
            @('shared_preferences', '^2.5.3'),
            @('url_launcher', '^6.3.0'),
            @('in_app_purchase', '^3.2.0'),
            @('share_plus', '^11.0.0')
        )
        foreach ($d in $deps) {
            if ($c -notmatch "(?m)^[ \t]+$($d[0]):") {
                $rx = [regex]'(?m)^([ \t]+path_provider:.*)$'
                if ($rx.IsMatch($c)) {
                    $c = $rx.Replace($c, "`$1`n  $($d[0]): $($d[1])", 1)
                    Write-Host "pubspec: added $($d[0])"
                } else {
                    throw "path_provider line not found in pubspec.yaml; add $($d[0]) manually"
                }
            }
        }
        return $c
    }
}

# --- Android Gradle: minSdk + compileSdk (Kotlin DSL and Groovy) ---
foreach ($f in @('android/app/build.gradle.kts', 'android/app/build.gradle')) {
    if (Test-Path $f) {
        Update-File $f {
            param($c)
            # minSdk
            $c = $c -replace 'flutter\.minSdkVersion', "$MinSdk"
            # compileSdk: from flutter.* default
            $c = $c -replace '(compileSdk(?:Version)?)(\s*=?\s*)flutter\.compileSdkVersion', "`${1}`${2}$CompileSdk"
            # compileSdk: from a hard-coded lower number
            $c = [regex]::Replace($c, '(compileSdk(?:Version)?\s*=?\s*)(\d+)', {
                param($m)
                if ([int]$m.Groups[2].Value -lt $CompileSdk) { $m.Groups[1].Value + $CompileSdk } else { $m.Value }
            })
            return $c
        }
        Write-Host '--- SDK lines now in' $f '---'
        Select-String -Path $f -Pattern 'compileSdk|minSdk|targetSdk|applicationId' | ForEach-Object { Write-Host $_.Line.Trim() }
    }
}

# --- gradle.properties: silence "AGP not tested with compileSdk 37" ---
$gp = 'android/gradle.properties'
if (Test-Path $gp) {
    $full = (Resolve-Path $gp).Path
    $c = [System.IO.File]::ReadAllText($full)
    if ($c -notmatch 'suppressUnsupportedCompileSdk') {
        if (-not $c.EndsWith("`n")) { $c += "`n" }
        $c += "android.suppressUnsupportedCompileSdk=$CompileSdk`n"
        [System.IO.File]::WriteAllText($full, $c, $utf8)
        Write-Host 'Added android.suppressUnsupportedCompileSdk'
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
