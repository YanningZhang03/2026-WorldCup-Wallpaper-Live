$ErrorActionPreference = "SilentlyContinue"

$packageRoot = $PSScriptRoot
$runtimeDir = Join-Path $packageRoot "runtime"
$profileDir = Join-Path $runtimeDir "edge-profile"
$statePath = Join-Path $runtimeDir "wallpaper-state.json"

$processes = Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine.Contains($profileDir) }

foreach ($process in $processes) {
  Stop-Process -Id $process.ProcessId -Force
}

Remove-Item -LiteralPath $statePath -Force
Write-Host "World Cup countdown wallpaper stopped."
