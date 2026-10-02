# Export GitHub social card: index.html -> og-image.png (1280x640, <1MB)
# Usage: powershell -ExecutionPolicy Bypass -File .\export-og.ps1
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Edge first, then Chrome
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) { $edge = "C:\Program Files\Google\Chrome\Application\chrome.exe" }
if (-not (Test-Path $edge)) { throw "Edge/Chrome not found, edit `$edge path" }

# Step 1: screenshot at 2x (2560x1280) for crisp text.
# NOTE: use an isolated user-data-dir, otherwise an already-running Edge
# instance swallows the command and we screenshot the new-tab page instead.
$html = "file:///" + (Join-Path $dir 'index.html').Replace('\','/')
$big  = Join-Path $dir 'og-image-2x.png'
$prof = Join-Path $env:TEMP 'og-shot-profile'
$eargs = @(
  '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run',
  '--force-device-scale-factor=2', '--window-size=1280,640',
  '--virtual-time-budget=8000',
  ('--user-data-dir=' + $prof),
  ('--screenshot=' + $big), $html
)
Start-Process -FilePath $edge -ArgumentList $eargs -Wait -WindowStyle Hidden

# Step 2: high-quality downscale back to 1280x640 (GitHub wants 2:1, <1MB).
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($big)
$bmp = New-Object System.Drawing.Bitmap 1280, 640
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$g.SmoothingMode = 'HighQuality'
$g.PixelOffsetMode = 'HighQuality'
$g.DrawImage($src, 0, 0, 1280, 640)
$g.Dispose(); $src.Dispose()

$out = Join-Path $dir 'og-image.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Remove-Item $big

$item = Get-Item $out
$kb = [math]::Round($item.Length / 1KB)
if ($item.Length -ge 1MB) { Write-Warning "File is ${kb}KB, over GitHub 1MB limit - simplify the background!" }
Write-Host "Exported: $out (${kb}KB, 1280x640)"
