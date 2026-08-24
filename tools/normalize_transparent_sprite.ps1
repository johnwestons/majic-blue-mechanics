param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [int]$CanvasSize = 256,
    [int]$Padding = 10
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$source = [System.Drawing.Bitmap]::new((Resolve-Path -LiteralPath $InputPath).Path)
try {
    $minX, $minY = $source.Width, $source.Height
    $maxX, $maxY = -1, -1
    for ($y = 0; $y -lt $source.Height; $y++) {
        for ($x = 0; $x -lt $source.Width; $x++) {
            if ($source.GetPixel($x, $y).A -gt 4) {
                $minX = [Math]::Min($minX, $x)
                $minY = [Math]::Min($minY, $y)
                $maxX = [Math]::Max($maxX, $x)
                $maxY = [Math]::Max($maxY, $y)
            }
        }
    }
    if ($maxX -lt 0) { throw 'The input image contains no visible pixels.' }

    $cropX = [Math]::Max(0, $minX - $Padding)
    $cropY = [Math]::Max(0, $minY - $Padding)
    $cropRight = [Math]::Min($source.Width - 1, $maxX + $Padding)
    $cropBottom = [Math]::Min($source.Height - 1, $maxY + $Padding)
    $cropWidth = $cropRight - $cropX + 1
    $cropHeight = $cropBottom - $cropY + 1
    $available = $CanvasSize - 2 * $Padding
    $scale = [Math]::Min($available / [double]$cropWidth, $available / [double]$cropHeight)
    $drawWidth = [Math]::Max(1, [int][Math]::Round($cropWidth * $scale))
    $drawHeight = [Math]::Max(1, [int][Math]::Round($cropHeight * $scale))
    $drawX = [int](($CanvasSize - $drawWidth) / 2)
    $drawY = [int](($CanvasSize - $drawHeight) / 2)

    $result = [System.Drawing.Bitmap]::new($CanvasSize, $CanvasSize,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($result)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $destination = [System.Drawing.Rectangle]::new($drawX, $drawY, $drawWidth, $drawHeight)
            $sourceRectangle = [System.Drawing.Rectangle]::new($cropX, $cropY, $cropWidth, $cropHeight)
            $graphics.DrawImage($source, $destination, $sourceRectangle,
                [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally { $graphics.Dispose() }
        $outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
        if (-not (Test-Path -LiteralPath $outputDirectory)) {
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        }
        $result.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $result.Dispose() }
    Write-Output ("SPRITE_NORMALIZED: {0} -> {1} canvas={2} bbox={3},{4},{5},{6}" -f
        $InputPath, $OutputPath, $CanvasSize, $minX, $minY, $maxX, $maxY)
}
finally { $source.Dispose() }
