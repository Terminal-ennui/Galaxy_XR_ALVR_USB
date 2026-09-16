param([string]$AdbPath = '', [string]$Serial = '')
$ErrorActionPreference = 'Stop'
try {
    if (!$AdbPath) {
        $local = Join-Path $PSScriptRoot 'platform-tools\adb.exe'
        if (Test-Path $local) { $AdbPath = $local }
        else { $AdbPath = (Get-Command adb.exe -ErrorAction Stop).Source }
    }
    if (!(Test-Path $AdbPath)) { throw 'adb.exe was not found. Extract platform-tools beside this script.' }
    & $AdbPath start-server
    if ($LASTEXITCODE -ne 0) { throw 'ADB could not start.' }
    $rows = @(& $AdbPath devices -l)
    if ($LASTEXITCODE -ne 0) { throw 'ADB could not list devices.' }
    if (!$Serial) {
        $headsets = @($rows | Where-Object { $_ -match '^\S+\s+device\s' -and $_ -match 'model:SM_I610\b' })
        if ($headsets.Count -ne 1) {
            throw "Expected one authorized Galaxy XR. Turn it on, connect a data cable, and accept USB debugging. If multiple headsets are connected, use -Serial. Device status: $($rows -join ' / ')"
        }
        $Serial = ($headsets[0] -split '\s+')[0]
    }
    & $AdbPath -s $Serial get-state
    if ($LASTEXITCODE -ne 0) { throw 'The selected headset is not available.' }
    foreach ($port in @(9943, 9944)) {
        & $AdbPath -s $Serial forward "tcp:$port" "tcp:$port"
        if ($LASTEXITCODE -ne 0) { throw "Could not forward port $port. Another application may already be using it." }
    }
    Write-Host 'USB forwarding is ready.' -ForegroundColor Green
    Write-Host 'Open ALVR on the headset. In the PC dashboard, trust it, set manual IP to 127.0.0.1, and select TCP streaming.'
    Write-Host 'Then start SteamVR. Run this script again after a USB reconnection, PC restart, or ADB restart.'
    Write-Host 'This script does not install an APK, change quality settings, or disable headset sleep.'
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
