param([Parameter(Mandatory=$true)][string]$Godot,
      [Parameter(Mandatory=$true)][string]$SigningConfig)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $projectRoot 'export/release'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$signing = Get-Content -LiteralPath $SigningConfig -Raw | ConvertFrom-Json
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $signing.path
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $signing.alias
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $signing.password
try {
    foreach ($target in @(@('Meta Quest','OceanVR-1.0.0-rc1-Quest2.apk'), @('Windows Desktop','OceanVR-1.0.0-rc1.exe'))) {
        $outputFile = Join-Path $destination $target[1]
        $arguments = @('--headless','--xr-mode','off','--path',('"'+$projectRoot+'"'),'--export-release',('"'+$target[0]+'"'),('"'+$outputFile+'"'),'--log-file',('"'+$outputFile+'.log"'))
        $build = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
        $build.WaitForExit()
        if ($build.ExitCode -ne 0 -or !(Test-Path -LiteralPath $outputFile)) { throw "Export failed: $($target[0])" }
    }
} finally {
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH,Env:GODOT_ANDROID_KEYSTORE_RELEASE_USER,Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
}
Get-ChildItem -LiteralPath $destination -File | Where-Object Extension -In '.apk','.exe','.pck','.dll' | Get-FileHash -Algorithm SHA256 | ForEach-Object { $_.Hash + '  ' + (Split-Path -Leaf $_.Path) } | Set-Content (Join-Path $destination 'SHA256SUMS.txt')
