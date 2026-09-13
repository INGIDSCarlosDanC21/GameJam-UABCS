param([Parameter(Mandatory=$true)][string]$Godot,
      [Parameter(Mandatory=$true)][string]$SigningConfig)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$versionLine = Select-String -LiteralPath (Join-Path $projectRoot 'project.godot') -Pattern '^config/version="([A-Za-z0-9.-]+)"$'
if (!$versionLine) { throw 'Missing project version.' }
$version = $versionLine.Matches[0].Groups[1].Value
$destination = Join-Path $projectRoot ('export/release/' + $version)
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$signing = Get-Content -LiteralPath $SigningConfig -Raw | ConvertFrom-Json
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $signing.path
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $signing.alias
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $signing.password
try {
    foreach ($target in @(@('Meta Quest',('OceanVR-'+$version+'-Quest2.apk')), @('Windows Desktop',('OceanVR-'+$version+'.exe')))) {
        $outputFile = Join-Path $destination $target[1]
        $arguments = @('--headless','--xr-mode','off','--path',('"'+$projectRoot+'"'),'--export-release',('"'+$target[0]+'"'),('"'+$outputFile+'"'),'--log-file',('"'+$outputFile+'.log"'))
        $build = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
        $build.WaitForExit()
        if ($build.ExitCode -ne 0 -or !(Test-Path -LiteralPath $outputFile)) { throw "Export failed: $($target[0])" }
    }
} finally {
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH,Env:GODOT_ANDROID_KEYSTORE_RELEASE_USER,Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/CREDITS.txt') -Destination (Join-Path $destination 'CREDITS.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/RELEASE_1_0.md') -Destination (Join-Path $destination 'RELEASE_NOTES.md')
$windowsFiles = @((Join-Path $destination ('OceanVR-'+$version+'.exe')), (Join-Path $destination ('OceanVR-'+$version+'.pck')), (Join-Path $destination 'libgodotopenxrvendors.dll'), (Join-Path $destination 'CREDITS.txt'), (Join-Path $destination 'RELEASE_NOTES.md'))
Compress-Archive -LiteralPath $windowsFiles -DestinationPath (Join-Path $destination ('OceanVR-'+$version+'-Windows.zip')) -Force
Get-ChildItem -LiteralPath $destination -File | Where-Object Extension -In '.apk','.exe','.pck','.dll','.zip' | Get-FileHash -Algorithm SHA256 | ForEach-Object { $_.Hash + '  ' + (Split-Path -Leaf $_.Path) } | Set-Content (Join-Path $destination 'SHA256SUMS.txt')
