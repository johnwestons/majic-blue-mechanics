param(
    [string]$ReportPath = (Join-Path $PSScriptRoot '..\output\asset-doctor-report.json')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()
$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $checks.Add([pscustomobject]@{ name = $Name; passed = $Passed; detail = $Detail })
    if (-not $Passed) { $failures.Add("$Name`: $Detail") }
}

function Get-ImageInfo {
    param([string]$RelativePath)
    $absolutePath = Join-Path $projectPath $RelativePath
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        Add-Check "exists:$RelativePath" $false 'required file is missing'
        return $null
    }
    $image = [System.Drawing.Image]::FromFile($absolutePath)
    try {
        Add-Check "exists:$RelativePath" $true "$($image.Width)x$($image.Height)"
        return [pscustomobject]@{
            path = $RelativePath
            absolutePath = $absolutePath
            width = $image.Width
            height = $image.Height
            pixelFormat = $image.PixelFormat.ToString()
        }
    }
    finally { $image.Dispose() }
}

$expected = [ordered]@{
    'assets\workshop\workshop-layout-v2.png' = @(1536, 1024)
    'assets\workshop\workshop-walkmask.png' = @(1536, 1024)
    'assets\motorcycles\gsxr-600-service.png' = @(256, 256)
    'assets\motorcycles\gsxr-600-poster.png' = @(128, 128)
    'assets\motorcycles\gsxr-600-action.png' = @(128, 128)
    'assets\tools\diagnostic-reader-frame-01.png' = @(256, 256)
    'assets\tools\diagnostic-reader-frame-02.png' = @(256, 256)
    'assets\tools\diagnostic-reader-frame-03.png' = @(256, 256)
    'assets\tools\diagnostic-reader-frame-04.png' = @(256, 256)
    'assets\road-test\parking-lot-option-a.png' = @(1024, 1536)
    'assets\road-test\industrial-road-segment-01.png' = @(1024, 1536)
    'assets\road-test\industrial-road-segment-02.png' = @(1024, 1536)
    'assets\road-test\industrial-road-segment-03.png' = @(1024, 1536)
    'assets\road-test\warehouse-street-view-01.png' = @(1024, 1536)
    'assets\road-test\warehouse-street-view-02.png' = @(1024, 1536)
    'assets\road-test\warehouse-street-view-03.png' = @(1024, 1536)
    'assets\road-test\warehouse-street-view-04.png' = @(1024, 1536)
    'assets\road-test\warehouse-street-view-05.png' = @(1024, 1536)
    'assets\road-test\runner-road-texture.png' = @(1254, 1254)
    'assets\road-test\runner-sky.png' = @(1024, 1536)
    'assets\road-test\runner-city-horizon.png' = @(1536, 1024)
    'assets\road-test\runner-fence-trees.png' = @(1672, 941)
    'assets\road-test\runner-warehouse-bay.png' = @(1619, 971)
    'assets\road-test\runner-clutter.png' = @(1536, 1024)
    'assets\road-test\runner-left-section.png' = @(2135, 736)
    'assets\road-test\runner-right-section.png' = @(2172, 724)
    'assets\road-test\runner-left-wall-texture-long.png' = @(2172, 724)
    'assets\road-test\runner-right-wall-texture-long.png' = @(2172, 724)
    'assets\road-test\mechanic-raccoon-rider.png' = @(256, 256)
    'assets\road-test\road-test-cone.png' = @(128, 128)
    'assets\characters\mechanic-raccoon\idle.png' = @(1024, 512)
    'assets\characters\mechanic-raccoon\walk.png' = @(3072, 512)
    'assets\characters\mechanic-raccoon\use.png' = @(1536, 512)
}

foreach ($graffiti in @('raccoon', 'fox', 'owl', 'snake', 'wrench', 'ride', 'shift', 'majic')) {
    $expected["assets\road-test\runner-graffiti-$graffiti.png"] = @(1254, 1254)
}

foreach ($traffic in @('hatchback-teal', 'sedan-orange', 'van-blue', 'pickup-olive')) {
    $expected["assets\road-test\traffic\traffic-$traffic.png"] = @(256, 256)
}

foreach ($frame in 1..4) {
    $expected["assets\road-test\rider-hit\frame-{0:D2}.png" -f $frame] = @(256, 256)
}

foreach ($bike in @('naked-black', 'vintage-red-standard', 'black-classic',
        'red-supersport', 'adventure-silver-red', 'red-vtwin-cruiser',
        'adventure-blue-white', 'ural-tan-classic', 'bmw-r24-vintage',
        'modern-gray-cruiser')) {
    $expected["assets\motorcycles\$bike-service.png"] = @(256, 256)
    $expected["assets\motorcycles\$bike-mounted.png"] = @(256, 256)
    $expected["assets\motorcycles\$bike-rear.png"] = @(256, 256)
}

foreach ($part in @('oil', 'brake', 'chain', 'stator', 'suspension',
        'belt', 'spoke', 'carb', 'magneto', 'coolant')) {
    $expected["assets\repair-parts\$part.png"] = @(128, 128)
}

foreach ($tool in @('ratchet', 'spanner', 'screwdriver', 'filter-wrench', 'funnel')) {
    $expected["assets\repair-tools\$tool.png"] = @(128, 128)
}

foreach ($character in @('business-dragon', 'business-fox', 'business-cat')) {
    $expected["assets\characters\$character\idle.png"] = @(1024, 512)
    $expected["assets\characters\$character\walk.png"] = @(2048, 512)
    $expected["assets\characters\$character\sit.png"] = @(1024, 512)
}

$imageInfo = @{}
foreach ($entry in $expected.GetEnumerator()) {
    $info = Get-ImageInfo $entry.Key
    if (-not $info) { continue }
    $imageInfo[$entry.Key] = $info
    $dimensionPassed = $info.width -eq $entry.Value[0] -and $info.height -eq $entry.Value[1]
    Add-Check "dimensions:$($entry.Key)" $dimensionPassed `
        "expected $($entry.Value[0])x$($entry.Value[1]); got $($info.width)x$($info.height)"
    if ($entry.Key -like 'assets\characters\*' -or
        $entry.Key -eq 'assets\motorcycles\gsxr-600-service.png' -or
        $entry.Key -like 'assets\motorcycles\*-service.png' -or
        $entry.Key -like 'assets\motorcycles\*-mounted.png' -or
        $entry.Key -like 'assets\motorcycles\*-rear.png' -or
        $entry.Key -like 'assets\repair-parts\*.png' -or
        $entry.Key -like 'assets\repair-tools\*.png' -or
        $entry.Key -like 'assets\road-test\runner-fence-trees.png' -or
        $entry.Key -like 'assets\road-test\runner-warehouse-bay.png' -or
        $entry.Key -like 'assets\road-test\runner-clutter.png' -or
        $entry.Key -like 'assets\road-test\runner-left-section.png' -or
        $entry.Key -like 'assets\road-test\runner-right-section.png' -or
        $entry.Key -like 'assets\road-test\runner-graffiti-*.png' -or
        $entry.Key -like 'assets\road-test\traffic\*.png' -or
        $entry.Key -like 'assets\road-test\rider-hit\*.png' -or
        $entry.Key -like 'assets\road-test\mechanic-raccoon-rider.png' -or
        $entry.Key -like 'assets\road-test\road-test-cone.png' -or
        $entry.Key -like 'assets\tools\diagnostic-reader-frame-*.png') {
        $alphaPassed = $info.pixelFormat -match 'Alpha|Argb|PArgb'
        Add-Check "alpha:$($entry.Key)" $alphaPassed "pixel format is $($info.pixelFormat)"
    }
}

$layout = $imageInfo['assets\workshop\workshop-layout-v2.png']
$mask = $imageInfo['assets\workshop\workshop-walkmask.png']
if ($layout -and $mask) {
    Add-Check 'workshop-mask-alignment' `
        ($layout.width -eq $mask.width -and $layout.height -eq $mask.height) `
        "layout $($layout.width)x$($layout.height); mask $($mask.width)x$($mask.height)"
}

if ($mask) {
    $bitmap = [System.Drawing.Bitmap]::new($mask.absolutePath)
    $nonBinary = 0
    try {
        for ($y = 0; $y -lt $bitmap.Height -and $nonBinary -eq 0; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                $black = $pixel.R -eq 0 -and $pixel.G -eq 0 -and $pixel.B -eq 0
                $white = $pixel.R -eq 255 -and $pixel.G -eq 255 -and $pixel.B -eq 255
                if (-not ($black -or $white)) { $nonBinary++; break }
            }
        }
    }
    finally { $bitmap.Dispose() }
    Add-Check 'walkmask-binary' ($nonBinary -eq 0) 'mask pixels must be only black or white'
}

$reportDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($ReportPath))
if (-not (Test-Path -LiteralPath $reportDirectory)) {
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}
$report = [pscustomobject]@{
    project = 'Majic Blue Mechanics'
    passed = $failures.Count -eq 0
    checkCount = $checks.Count
    failureCount = $failures.Count
    checks = $checks
    failures = $failures
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding UTF8

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    exit 1
}
Write-Output "ASSET_DOCTOR_OK: $($checks.Count) checks passed"
