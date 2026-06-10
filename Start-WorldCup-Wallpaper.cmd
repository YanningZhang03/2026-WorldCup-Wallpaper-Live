@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-WorldCup-Wallpaper.ps1"
if errorlevel 1 (
  echo.
  echo Failed to start the wallpaper. Please check the error above.
  pause
)
