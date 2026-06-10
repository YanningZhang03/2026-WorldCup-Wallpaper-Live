@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Stop-WorldCup-Wallpaper.ps1"
if errorlevel 1 (
  echo.
  echo Failed to stop the wallpaper. Please check the error above.
  pause
)
