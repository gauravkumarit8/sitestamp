# Adds release signing (key.properties) to android/app/build.gradle.kts.
# Run by the Release workflow only; the Build workflow never touches signing.
# Idempotent. Fails loudly (and prints the file) if the layout is unexpected.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$f = 'android/app/build.gradle.kts'

if (-not (Test-Path $f)) {
    if (Test-Path 'android/app/build.gradle') {
        throw 'Groovy build.gradle found; this script supports build.gradle.kts only. Paste the file to Claude.'
    }
    throw "$f not found"
}

$full = (Resolve-Path $f).Path
$c = [System.IO.File]::ReadAllText($full)

function Fail([string]$msg) {
    Write-Host '----- android/app/build.gradle.kts -----'
    Write-Host $c
    Write-Host '----------------------------------------'
    throw $msg
}

if ($c -match 'keystoreProperties') {
    Write-Host 'Signing already configured.'
    exit 0
}

# 1) insert a signingConfigs block right before buildTypes (later edit first)
$mBuild = ([regex]'(?m)^([ \t]*)buildTypes\s*\{').Match($c)
if (-not $mBuild.Success) { Fail 'buildTypes block not found' }
$ind = $mBuild.Groups[1].Value
$lines = @(
    'signingConfigs {',
    '    create("release") {',
    '        keyAlias = keystoreProperties["keyAlias"] as String?',
    '        keyPassword = keystoreProperties["keyPassword"] as String?',
    '        storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }',
    '        storePassword = keystoreProperties["storePassword"] as String?',
    '    }',
    '}'
)
$block = (($lines | ForEach-Object { $ind + $_ }) -join "`n") + "`n`n"
$c = $c.Insert($mBuild.Index, $block)

# 2) release buildType uses the release signing config
$old = 'signingConfig = signingConfigs.getByName("debug")'
if ($c.Contains($old)) {
    $c = $c.Replace($old, 'signingConfig = signingConfigs.getByName("release")')
} else {
    Fail 'debug signingConfig line not found in release buildType'
}

# 3) read key.properties above the android { } block
$mAndroid = ([regex]'(?m)^android\s*\{').Match($c)
if (-not $mAndroid.Success) { Fail 'android { block not found' }
$header = @'
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


'@
$c = $c.Insert($mAndroid.Index, $header)

# `java.util.Properties` does not resolve inside Gradle Kotlin scripts (`java` is
# Gradle's extension), so use imports at the top of the file instead.
$imports = "import java.io.FileInputStream`nimport java.util.Properties`n`n"
$c = $imports + $c

[System.IO.File]::WriteAllText($full, $c, $utf8)
Write-Host 'Release signing configured in build.gradle.kts'
Select-String -Path $f -Pattern 'signingConfig|keystoreProperties' | ForEach-Object { Write-Host $_.Line.Trim() }
