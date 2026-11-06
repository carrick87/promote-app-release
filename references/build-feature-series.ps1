# Builds a web feature series (cover + one 1920x1080 image per feature) from real screenshots.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File build-feature-series.ps1 -Spec path\to\feature-series.json
param([Parameter(Mandatory = $true)][string]$Spec)

Add-Type -AssemblyName System.Drawing
$cfg = Get-Content -Raw -Encoding UTF8 $Spec | ConvertFrom-Json
$specDir = Split-Path -Parent (Resolve-Path $Spec)
function Abs([string]$p) { if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $specDir $p } }

$shots = Abs $cfg.shotsDir
$out   = Abs $cfg.outDir
$icon  = Abs $cfg.icon
New-Item -ItemType Directory -Force $out | Out-Null

$fonts = Join-Path $env:TEMP "promo-fonts"
New-Item -ItemType Directory -Force $fonts | Out-Null
foreach ($f in $cfg.fonts.files) {
  $dest = Join-Path $fonts $f.file
  if (-not (Test-Path $dest)) { Invoke-WebRequest $f.url -OutFile $dest -UseBasicParsing }
}
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
foreach ($f in $cfg.fonts.files) { $pfc.AddFontFile((Join-Path $fonts $f.file)) }
function Fam([string]$n) {
  $x = $pfc.Families | Where-Object { $_.Name -eq $n } | Select-Object -First 1
  if (-not $x) { throw "Font family '$n' not loaded" }; $x
}
$fSans = Fam $cfg.fonts.regular; $fSemi = Fam $cfg.fonts.semibold; $fMono = Fam $cfg.fonts.mono
$PX = [System.Drawing.GraphicsUnit]::Pixel
function F($fam, [single]$size) { New-Object System.Drawing.Font($fam, $size, [System.Drawing.FontStyle]::Regular, $PX) }

function C([string]$hex, [int]$a = 255) {
  $h = $hex.TrimStart('#')
  [System.Drawing.Color]::FromArgb($a, [Convert]::ToInt32($h.Substring(0,2),16), [Convert]::ToInt32($h.Substring(2,2),16), [Convert]::ToInt32($h.Substring(4,2),16))
}
function B([string]$hex, [int]$a = 255) { New-Object System.Drawing.SolidBrush (C $hex $a) }
$DOT = [string][char]0x00B7
$P = $cfg.palette
$BG = $P.background; $INK = $P.ink; $BRAND = $P.brand; $BODY = $P.body; $MUTED = $P.muted; $RULE = $P.rule; $CHROME = $P.chrome

function RoundPath([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath; $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); return $p
}

function Tracked($g, [string]$text, $font, $brush, [single]$x, [single]$y, [single]$track) {
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  foreach ($ch in $text.ToCharArray()) {
    $s = [string]$ch
    $g.DrawString($s, $font, $brush, $x, $y, $fmt)
    $w = if ($s -eq ' ') { $font.Size * 0.28 } else { $g.MeasureString($s, $font, 1000, $fmt).Width }
    $x += $w + $track
  }
}

function TextBlock($g, [string]$text, $font, $brush, [single]$x, [single]$y, [single]$w, [single]$lineH) {
  $words = $text -split ' '; $line = ''; $lines = @()
  foreach ($wd in $words) {
    $try = if ($line) { "$line $wd" } else { $wd }
    if ($g.MeasureString($try, $font).Width -gt $w -and $line) { $lines += $line; $line = $wd } else { $line = $try }
  }
  if ($line) { $lines += $line }
  $i = 0
  foreach ($l in $lines) { $g.DrawString($l, $font, $brush, $x - 2, $y + $i * $lineH); $i++ }
  return $lines.Count * $lineH
}

function Badge($g, [single]$cx, [single]$cy, [single]$d, [string]$n) {
  $g.FillEllipse((B $INK), $cx - $d/2, $cy - $d/2, $d, $d)
  $g.DrawEllipse((New-Object System.Drawing.Pen((C "#FFFFFF"), 2)), $cx - $d/2, $cy - $d/2, $d, $d)
  $sf = New-Object System.Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
  $g.DrawString($n, (F $fMono ([single]($d * 0.5))), [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(($cx - $d/2), ($cy - $d/2 + 1), $d, $d)), $sf)
}

function Shadow($g, [single]$x, [single]$y, [single]$w, [single]$h) {
  for ($i = 28; $i -ge 1; $i -= 2) {
    $a = [int](10 * [Math]::Pow((1 - $i / 30.0), 2)) + 1
    $g.FillPath((B $INK $a), (RoundPath ($x - $i/2) ($y - $i/2 + 14) ($w + $i) ($h + $i) (12 + $i/2)))
  }
}

function Frame($g, [string]$shot, $crop, [single]$fx, [single]$fy, [single]$fw, $outlines, $markers, [bool]$dim) {
  $src = [System.Drawing.Image]::FromFile($shot)
  $scale = $fw / $crop[2]; $ih = $crop[3] * $scale; $fh = 40 + $ih
  Shadow $g $fx $fy $fw $fh
  $frame = RoundPath $fx $fy $fw $fh 12
  $g.FillPath([System.Drawing.Brushes]::White, $frame)
  $g.SetClip($frame)
  $g.FillRectangle((B $CHROME), $fx, $fy, $fw, 40)
  foreach ($k in 0..2) { $g.FillEllipse((B "#C9CFD8"), $fx + 18 + $k * 20, $fy + 14, 12, 12) }
  $g.FillPath([System.Drawing.Brushes]::White, (RoundPath ($fx + 96) ($fy + 8) 380 24 12))
  $g.DrawString($cfg.urlLabel, (F $fSans 13), (B $MUTED), ($fx + 112), ($fy + 11))
  $g.DrawLine((New-Object System.Drawing.Pen((C $RULE), 1)), $fx, $fy + 40, $fx + $fw, $fy + 40)
  $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
  $dest = New-Object System.Drawing.RectangleF($fx, ($fy + 40), $fw, $ih)
  $g.DrawImage($src, $dest, (New-Object System.Drawing.RectangleF($crop[0], $crop[1], $crop[2], $crop[3])), $PX)
  $map = { param($sx, $sy) @(($fx + ($sx - $crop[0]) * $scale), ($fy + 40 + ($sy - $crop[1]) * $scale)) }.GetNewClosure()

  if ($dim -and $outlines) {
    $region = New-Object System.Drawing.Region($dest); $paths = @()
    foreach ($o in $outlines) {
      $a = & $map $o[0] $o[1]
      $p = RoundPath ($a[0] - 6) ($a[1] - 6) ($o[2] * $scale + 12) ($o[3] * $scale + 12) 8
      $region.Exclude($p); $paths += $p
    }
    $g.FillRegion((B "#FFFFFF" 150), $region)
    $pen = New-Object System.Drawing.Pen((C $BRAND), 2)
    foreach ($p in $paths) { $g.DrawPath($pen, $p) }
  }
  $g.ResetClip()
  $g.DrawPath((New-Object System.Drawing.Pen((C $RULE), 1)), $frame)
  foreach ($m in $markers) { $a = & $map $m[0] $m[1]; Badge $g $a[0] $a[1] 36 ([string]$m[2]) }
  $src.Dispose()
}

function Footer($g, [string]$right) {
  $g.DrawLine((New-Object System.Drawing.Pen((C $RULE), 1)), 96, 952, 1824, 952)
  $ic = [System.Drawing.Image]::FromFile($icon)
  $g.DrawImage($ic, (New-Object System.Drawing.RectangleF(96, 976, 28, 28))); $ic.Dispose()
  $f = F $fSans 18
  $g.DrawString("$($cfg.product)  $DOT  v$($cfg.version)", $f, (B $INK), 136, 979)
  $sf = New-Object System.Drawing.StringFormat; $sf.Alignment = 'Far'
  $g.DrawString($right, $f, (B $MUTED), (New-Object System.Drawing.RectangleF(900, 979, 924, 30)), $sf)
}

function NewCanvas() {
  $bmp = New-Object System.Drawing.Bitmap 1920, 1080
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
  $g.Clear((C $BG))
  return @($bmp, $g)
}

$prefix = "$($cfg.filePrefix)-$($cfg.version)-feature"
$count = "{0:D2}" -f $cfg.features.Count
$fx = 680; $fw = 1144

foreach ($ft in $cfg.features) {
  $c = NewCanvas; $bmp = $c[0]; $g = $c[1]
  $fh = 40 + $ft.crop[3] * ($fw / $ft.crop[2])
  Frame $g (Join-Path $shots $ft.shot) $ft.crop $fx (88 + (824 - $fh) / 2) $fw $ft.outlines $ft.markers $true

  $fTitle = F $fSemi 60; $fBody = F $fSans 28; $fBul = F $fSans 24; $fEye = F $fSemi 20
  $tmp = New-Object System.Drawing.Bitmap 10, 10; $tg = [System.Drawing.Graphics]::FromImage($tmp)
  $hTitle = TextBlock $tg $ft.title $fTitle ([System.Drawing.Brushes]::Black) 0 0 560 66
  $hBody = TextBlock $tg $ft.body $fBody ([System.Drawing.Brushes]::Black) 0 0 552 41
  $bulH = @(); foreach ($b in $ft.bullets) { $bulH += (TextBlock $tg $b.text $fBul ([System.Drawing.Brushes]::Black) 0 0 500 34) }
  $tg.Dispose(); $tmp.Dispose()
  $total = 48 + $hTitle + 32 + $hBody + 48 + ($bulH | Measure-Object -Sum).Sum + 20 * ($bulH.Count - 1)
  $y = 88 + (824 - $total) / 2

  Tracked $g "FEATURE $($ft.n)  $DOT  $($ft.tag)" $fEye (B $BRAND) 96 $y 1.6
  $y += 48
  $y += TextBlock $g $ft.title $fTitle (B $INK) 96 $y 560 66
  $y += 32
  $y += TextBlock $g $ft.body $fBody (B $BODY) 96 $y 552 41
  $y += 48
  foreach ($b in $ft.bullets) {
    if ($b.n) { Badge $g 110 ($y + 17) 28 ([string]$b.n) } else { $g.FillRectangle((B $BRAND), 104, ($y + 11), 12, 12) }
    $y += (TextBlock $g $b.text $fBul (B $INK) 144 $y 500 34) + 20
  }
  Footer $g "$($cfg.company)  $DOT  Internal      $($ft.n) / $count"
  $name = "$prefix-$($ft.n)-" + (($ft.title.ToLower() -replace '[^a-z0-9]+','-').Trim('-')) + ".png"
  $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  $name
}

$cv = $cfg.cover
$c = NewCanvas; $bmp = $c[0]; $g = $c[1]
$fh = 40 + $cv.crop[3] * ($fw / $cv.crop[2])
Frame $g (Join-Path $shots $cv.shot) $cv.crop $fx (88 + (824 - $fh) / 2) $fw $null @() $false
$ic = [System.Drawing.Image]::FromFile($icon); $g.DrawImage($ic, (New-Object System.Drawing.RectangleF(96, 128, 64, 64))); $ic.Dispose()
$y = 224
Tracked $g $cv.eyebrow (F $fSemi 20) (B $BRAND) 96 $y 1.6
$y += 40
$y += TextBlock $g $cfg.product (F $fSemi 84) (B $INK) 96 $y 560 92
$y += 16
$y += TextBlock $g $cv.subtitle (F $fSans 30) (B $BODY) 96 $y 520 42
$y += 40
$g.DrawLine((New-Object System.Drawing.Pen((C $RULE), 1)), 96, $y, 616, $y)
$y += 28
Tracked $g "NEW IN $($cfg.version)" (F $fSemi 18) (B $MUTED) 96 $y 1.6
$y += 40
foreach ($t in $cv.newItems) {
  $g.FillRectangle((B $BRAND), 98, ($y + 11), 12, 12)
  $y += (TextBlock $g $t (F $fSans 24) (B $INK) 132 $y 524 34) + 14
}
Footer $g "$($cfg.company)  $DOT  Internal      $($cfg.features.Count) features inside"
$bmp.Save((Join-Path $out "$prefix-00-cover.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"$prefix-00-cover.png"
