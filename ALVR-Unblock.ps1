# Clears only SteamVR's ALVR safe-mode block. Close SteamVR before running.
param([string]$SettingsPath = '')
$ErrorActionPreference = 'Stop'
try {
    if (Get-Process -Name vrserver, vrcompositor, vrmonitor -ErrorAction SilentlyContinue) {
        throw 'Close SteamVR first, then run ALVR-Unblock again. No settings were changed.'
    }
    if (!$SettingsPath) {
        $SettingsPath = Join-Path ${env:ProgramFiles(x86)} 'Steam\config\steamvr.vrsettings'
    }
    if (!(Test-Path -LiteralPath $SettingsPath -PathType Leaf)) {
        throw 'SteamVR settings were not found. For a custom Steam installation, pass -SettingsPath with the full steamvr.vrsettings path.'
    }
    $settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
    if (!$settings -or $settings -isnot [PSCustomObject]) {
        throw 'SteamVR settings are not a JSON object. No settings were changed.'
    }
    if (!$settings.driver_alvr_server -or !$settings.driver_alvr_server.blocked_by_safe_mode) {
        Write-Host 'ALVR is not blocked in this settings file. Nothing changed.'
        exit 0
    }
    $settings.driver_alvr_server.blocked_by_safe_mode = $false
    $updated = $settings | ConvertTo-Json -Depth 100
    $backupPath = $SettingsPath + '.alvr-unblock-' + [Guid]::NewGuid().ToString('N') + '.bak'
    Copy-Item -LiteralPath $SettingsPath -Destination $backupPath -ErrorAction Stop
    [System.IO.File]::WriteAllText((Get-Item -LiteralPath $SettingsPath).FullName, $updated, [System.Text.UTF8Encoding]::new($false))
    Write-Host 'ALVR unblocked. Open the ALVR dashboard, then start SteamVR.' -ForegroundColor Green
    Write-Host "Backup: $backupPath"
    Write-Host 'ALVR quality settings were not changed. Fix the original crash first or SteamVR may block ALVR again.'
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
