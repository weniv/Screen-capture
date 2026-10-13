# 발바닥.svg 와 같은 도형으로 exe 에 넣을 아이콘(발바닥.ico)을 만든다.
# 도형이 원 4개와 베지어 1개뿐이라 SVG 해석기 없이 System.Drawing 으로 그대로 그린다.
# 발바닥.svg 를 고치면 아래 좌표도 함께 고치고 이 스크립트를 다시 실행할 것.
Add-Type -AssemblyName System.Drawing

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $here '발바닥.ico'
$sizes = 16, 20, 24, 32, 40, 48, 64, 256
$color = [System.Drawing.Color]::FromArgb(0, 110, 207)   # #006ECF

$pngs = foreach ($n in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap $n, $n, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.PixelOffsetMode = 'HighQuality'
    $g.ScaleTransform($n / 256.0, $n / 256.0)
    $b = New-Object System.Drawing.SolidBrush $color
    foreach ($c in @(@(45, 108, 23), @(94, 64, 27), @(162, 64, 27), @(211, 108, 23))) {
        $g.FillEllipse($b, $c[0] - $c[2], $c[1] - $c[2], $c[2] * 2, $c[2] * 2)
    }
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddBezier(128, 110, 166, 110, 194, 134, 194, 168)
    $p.AddBezier(194, 168, 194, 200, 165, 218, 128, 218)
    $p.AddBezier(128, 218, 91, 218, 62, 200, 62, 168)
    $p.AddBezier(62, 168, 62, 134, 90, 110, 128, 110)
    $p.CloseFigure()
    $g.FillPath($b, $p)
    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    , $ms.ToArray()
}

# ICO 파일 : 헤더 6바이트 + 항목 16바이트씩 + PNG 본문 (Vista 이후 PNG 항목 지원)
$fs = [System.IO.File]::Create($out)
$w = New-Object System.IO.BinaryWriter $fs
$w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $n = $sizes[$i]
    $w.Write([byte]($n % 256)); $w.Write([byte]($n % 256))   # 256 은 0 으로 적는다
    $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([UInt16]1); $w.Write([UInt16]32)
    $w.Write([UInt32]$pngs[$i].Length); $w.Write([UInt32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($png in $pngs) { $w.Write($png) }
$w.Close()
Write-Host "만듦: $out"
