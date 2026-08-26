param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\output\visual-regression')
)

$ErrorActionPreference = 'Stop'
$workspacePath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runnerPath = Join-Path $PSScriptRoot 'run-smoke.ps1'
$loveCapture = Join-Path $env:APPDATA 'LOVE\majic-blue-mechanics-smoke\smoke-preview.png'
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)

$scenes = @(
    @{ Name = 'title'; Preview = 'title' },
    @{ Name = 'world'; Preview = 'world' },
    @{ Name = 'estimate'; Preview = 'job_offer' },
    @{ Name = 'computer-active'; Preview = 'computer'; ComputerTab = '1' },
    @{ Name = 'computer-parts'; Preview = 'computer'; ComputerTab = '3' },
    @{ Name = 'service'; Preview = 'service' },
    @{ Name = 'diagnostic'; Preview = 'diagnostic' },
    @{ Name = 'repair-part'; Preview = 'repair'; RepairPhase = 'part' },
    @{ Name = 'repair-tool'; Preview = 'repair'; RepairPhase = 'tool' },
    @{ Name = 'road-test'; Preview = 'road_test' },
    @{ Name = 'parts-van'; Preview = 'parts_van' },
    @{ Name = 'delivery-manifest'; Preview = 'delivery_manifest' },
    @{ Name = 'flatbed-inbound'; Preview = 'flatbed_inbound' },
    @{ Name = 'flatbed-outbound'; Preview = 'flatbed_outbound' }
)

$previous = @{
    Preview = $env:MAJIC_BLUE_PREVIEW
    Screenshot = $env:MAJIC_BLUE_SMOKE_SCREENSHOT
    ComputerTab = $env:MAJIC_BLUE_COMPUTER_TAB
    RepairPhase = $env:MAJIC_BLUE_REPAIR_PREVIEW
}

New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$results = @()
try {
    $env:MAJIC_BLUE_SMOKE_SCREENSHOT = '1'
    foreach ($scene in $scenes) {
        $env:MAJIC_BLUE_PREVIEW = $scene.Preview
        if ($scene.ComputerTab) { $env:MAJIC_BLUE_COMPUTER_TAB = $scene.ComputerTab }
        else { Remove-Item Env:MAJIC_BLUE_COMPUTER_TAB -ErrorAction SilentlyContinue }
        if ($scene.RepairPhase) { $env:MAJIC_BLUE_REPAIR_PREVIEW = $scene.RepairPhase }
        else { Remove-Item Env:MAJIC_BLUE_REPAIR_PREVIEW -ErrorAction SilentlyContinue }

        & $runnerPath
        if ($LASTEXITCODE -ne 0) { throw "Scene '$($scene.Name)' failed smoke validation." }
        if (-not (Test-Path -LiteralPath $loveCapture)) {
            throw "Scene '$($scene.Name)' did not produce a screenshot."
        }
        $target = Join-Path $resolvedOutput ($scene.Name + '.png')
        Copy-Item -LiteralPath $loveCapture -Destination $target -Force
        $bytes = [System.IO.File]::ReadAllBytes($target)
        $validPng = $bytes.Length -ge 24 -and $bytes[0] -eq 137 -and $bytes[1] -eq 80 -and $bytes[2] -eq 78 -and $bytes[3] -eq 71
        if (-not $validPng) {
            throw "Scene '$($scene.Name)' is not a valid PNG capture."
        }
        $width = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($bytes, 16))
        $height = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($bytes, 20))
        if ($width -ne 960 -or $height -ne 678) {
            throw "Scene '$($scene.Name)' rendered ${width}x${height}; expected 960x678."
        }
        $file = Get-Item -LiteralPath $target
        $results += [ordered]@{
            scene = $scene.Name
            file = $file.Name
            width = $width
            height = $height
            bytes = $file.Length
            sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    $manifest = [ordered]@{
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        logicalCanvas = '960x678'
        sceneCount = $results.Count
        scenes = $results
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $resolvedOutput 'manifest.json')
    Write-Host "VISUAL_OK: captured and validated $($results.Count) scenes in $resolvedOutput"
}
finally {
    foreach ($entry in @(
        @{ Name = 'MAJIC_BLUE_PREVIEW'; Value = $previous.Preview },
        @{ Name = 'MAJIC_BLUE_SMOKE_SCREENSHOT'; Value = $previous.Screenshot },
        @{ Name = 'MAJIC_BLUE_COMPUTER_TAB'; Value = $previous.ComputerTab },
        @{ Name = 'MAJIC_BLUE_REPAIR_PREVIEW'; Value = $previous.RepairPhase }
    )) {
        if ($null -eq $entry.Value) { Remove-Item ("Env:" + $entry.Name) -ErrorAction SilentlyContinue }
        else { Set-Item ("Env:" + $entry.Name) $entry.Value }
    }
}
