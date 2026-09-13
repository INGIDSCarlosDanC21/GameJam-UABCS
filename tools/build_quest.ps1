param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [switch]$Install,
    [string]$Adb = "adb"
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $projectRoot 'export/quest/OceanVR-Quest2.apk'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputPath) | Out-Null
# Requires the matching Android build template installed from Godot's Project menu.
$arguments = @('--headless', '--xr-mode', 'off', '--path', ('"' + $projectRoot + '"'), '--export-debug', '"Meta Quest"', ('"' + $outputPath + '"'), '--log-file', ('"' + (Join-Path $projectRoot 'export/quest/build.log') + '"'))
$build = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
# Wait for Godot only: Gradle's background daemon deliberately stays alive.
$build.WaitForExit()
if ($build.ExitCode -ne 0) { throw "Quest export failed: exit $($build.ExitCode)" }
if (!(Test-Path -LiteralPath $outputPath)) { throw 'Godot did not produce an APK.' }
Get-Item -LiteralPath $outputPath
if ($Install) {
    & $Adb install -r $outputPath
    if ($LASTEXITCODE -ne 0) { throw 'ADB install failed; check USB debugging authorization in the headset.' }
}
