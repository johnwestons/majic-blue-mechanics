param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [int]$FrameCount = 4
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Bitmap]::new((Resolve-Path -LiteralPath $InputPath).Path)
try {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    for ($index = 0; $index -lt $FrameCount; $index++) {
        $left = [int][Math]::Floor($index * $source.Width / [double]$FrameCount)
        $right = [int][Math]::Floor(($index + 1) * $source.Width / [double]$FrameCount)
        $frameWidth = $right - $left
        $frame = $source.Clone([System.Drawing.Rectangle]::new($left, 0, $frameWidth, $source.Height),
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $path = Join-Path $OutputDirectory ("frame-{0:D2}.png" -f ($index + 1))
            $frame.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $frame.Dispose() }
    }
}
finally { $source.Dispose() }
Write-Output "SPRITE_STRIP_SPLIT: $InputPath -> $OutputDirectory ($FrameCount frames)"
