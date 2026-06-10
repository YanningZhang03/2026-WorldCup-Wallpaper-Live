$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$wallpaperPath = Join-Path $packageRoot "worldcup-countdown-wallpaper.html"
$runtimeDir = Join-Path $packageRoot "runtime"
$profileDir = Join-Path $runtimeDir "edge-profile"
$statePath = Join-Path $runtimeDir "wallpaper-state.json"

if (-not (Test-Path -LiteralPath $wallpaperPath)) {
  throw "Wallpaper HTML not found: $wallpaperPath"
}

New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

$edgeCandidates = @(
  (Get-Command msedge.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
$edgeCandidates = @($edgeCandidates)

if (-not $edgeCandidates) {
  throw "Microsoft Edge was not found. Please install Microsoft Edge first."
}

$edgePath = $edgeCandidates[0]

if (-not ("WorldCupWallpaper.NativeMethods" -as [type])) {
  Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace WorldCupWallpaper {
  public static class NativeMethods {
    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    private static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);

    [DllImport("user32.dll", EntryPoint="GetWindowLong", SetLastError=true)]
    private static extern int GetWindowLong32(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint="GetWindowLongPtr", SetLastError=true)]
    private static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint="SetWindowLong", SetLastError=true)]
    private static extern int SetWindowLong32(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", EntryPoint="SetWindowLongPtr", SetLastError=true)]
    private static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    private const int GWL_STYLE = -16;
    private const int SW_SHOW = 5;
    private const uint SMTO_NORMAL = 0x0000;
    private const uint SWP_NOZORDER = 0x0004;
    private const uint SWP_NOACTIVATE = 0x0010;
    private const uint SWP_FRAMECHANGED = 0x0020;

    private const long WS_CHILD = 0x40000000L;
    private const long WS_VISIBLE = 0x10000000L;
    private const long WS_CAPTION = 0x00C00000L;
    private const long WS_THICKFRAME = 0x00040000L;
    private const long WS_SYSMENU = 0x00080000L;
    private const long WS_MINIMIZEBOX = 0x00020000L;
    private const long WS_MAXIMIZEBOX = 0x00010000L;
    private const long WS_POPUP = unchecked((long)0x80000000);

    private static IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex) {
      return IntPtr.Size == 8 ? GetWindowLongPtr64(hWnd, nIndex) : new IntPtr(GetWindowLong32(hWnd, nIndex));
    }

    private static IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr value) {
      return IntPtr.Size == 8 ? SetWindowLongPtr64(hWnd, nIndex, value) : new IntPtr(SetWindowLong32(hWnd, nIndex, value.ToInt32()));
    }

    public static IntPtr GetDesktopHost() {
      IntPtr progman = FindWindow("Progman", null);
      IntPtr result;
      SendMessageTimeout(progman, 0x052C, IntPtr.Zero, IntPtr.Zero, SMTO_NORMAL, 1000, out result);

      IntPtr workerw = IntPtr.Zero;
      EnumWindows(delegate(IntPtr topHandle, IntPtr topParam) {
        IntPtr shellView = FindWindowEx(topHandle, IntPtr.Zero, "SHELLDLL_DefView", null);
        if (shellView != IntPtr.Zero) {
          workerw = FindWindowEx(IntPtr.Zero, topHandle, "WorkerW", null);
          return false;
        }
        return true;
      }, IntPtr.Zero);

      return workerw != IntPtr.Zero ? workerw : progman;
    }

    public static IntPtr FindWindowByTitle(string titlePart) {
      IntPtr found = IntPtr.Zero;
      EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
        if (!IsWindowVisible(hWnd)) {
          return true;
        }

        int length = GetWindowTextLength(hWnd);
        if (length <= 0) {
          return true;
        }

        StringBuilder builder = new StringBuilder(length + 1);
        GetWindowText(hWnd, builder, builder.Capacity);
        string title = builder.ToString();
        if (title.IndexOf(titlePart, StringComparison.OrdinalIgnoreCase) >= 0) {
          found = hWnd;
          return false;
        }

        return true;
      }, IntPtr.Zero);

      return found;
    }

    public static void AttachAsWallpaper(IntPtr hWnd, IntPtr parent, int x, int y, int width, int height) {
      long style = GetWindowLongPtr(hWnd, GWL_STYLE).ToInt64();
      style &= ~(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_POPUP);
      style |= WS_CHILD | WS_VISIBLE;

      SetWindowLongPtr(hWnd, GWL_STYLE, new IntPtr(style));
      SetParent(hWnd, parent);
      MoveWindow(hWnd, x, y, width, height, true);
      SetWindowPos(hWnd, IntPtr.Zero, x, y, width, height, SWP_NOACTIVATE | SWP_FRAMECHANGED);
      ShowWindow(hWnd, SW_SHOW);
    }
  }
}
"@
}

Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$titleBarTrim = 48
$wallpaperUri = ([System.Uri]::new((Resolve-Path -LiteralPath $wallpaperPath).Path)).AbsoluteUri

$existing = Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine.Contains($profileDir) }
foreach ($item in $existing) {
  Stop-Process -Id $item.ProcessId -Force -ErrorAction SilentlyContinue
}

$arguments = @(
  "--user-data-dir=$profileDir",
  "--app=$wallpaperUri",
  "--window-position=$($screen.Left),$($screen.Top - $titleBarTrim)",
  "--window-size=$($screen.Width),$($screen.Height + $titleBarTrim)",
  "--no-first-run",
  "--disable-session-crashed-bubble",
  "--disable-features=Translate,msEdgeShoppingAssistantEnabled",
  "--autoplay-policy=no-user-gesture-required"
)

$process = Start-Process -FilePath $edgePath -ArgumentList $arguments -PassThru
$hostWindow = [IntPtr]::Zero

for ($attempt = 0; $attempt -lt 80; $attempt += 1) {
  Start-Sleep -Milliseconds 250
  $hostWindow = [WorldCupWallpaper.NativeMethods]::FindWindowByTitle("World Cup Countdown Wallpaper")
  if ($hostWindow -ne [IntPtr]::Zero) {
    break
  }
}

if ($hostWindow -eq [IntPtr]::Zero) {
  throw "The wallpaper window did not appear."
}

$desktopHost = [WorldCupWallpaper.NativeMethods]::GetDesktopHost()
if ($desktopHost -eq [IntPtr]::Zero) {
  throw "The desktop host window was not found."
}

[WorldCupWallpaper.NativeMethods]::AttachAsWallpaper(
  $hostWindow,
  $desktopHost,
  $screen.Left,
  $screen.Top - $titleBarTrim,
  $screen.Width,
  $screen.Height + $titleBarTrim
)

@{
  processId = $process.Id
  profileDir = $profileDir
  wallpaper = $wallpaperPath
  startedAt = (Get-Date).ToString("o")
} | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8

Write-Host "World Cup countdown wallpaper is running."
