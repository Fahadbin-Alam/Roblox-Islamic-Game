$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$hubWorldBuilderPath = Join-Path $root "src\ServerScriptService\HubWorldBuilder.server.lua"
$hubAtmospherePath = Join-Path $root "src\ServerScriptService\HubAtmosphere.server.lua"
$buildPath = if ($BuildPath) { $BuildPath } else { Join-Path $root "build.rbxlx" }

function Assert-Contains {
    param(
        [string] $Text,
        [string] $Needle,
        [string] $Label
    )

    if (-not $Text.Contains($Needle)) {
        throw "Missing $Label`: $Needle"
    }
}

$hubWorldBuilder = Get-Content -LiteralPath $hubWorldBuilderPath -Raw
$hubAtmosphere = Get-Content -LiteralPath $hubAtmospherePath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$worldChecks = @(
    'local function createDistrictTerrainBand',
    'local function createWorldBackdrop',
    'createDistrictTerrainBand(geometryFolder, "MeccaWorld"',
    'createDistrictTerrainBand(geometryFolder, "MedinaWorld"',
    'createDistrictTerrainBand(geometryFolder, "JourneyWorld"',
    'WorldBackdrop',
    'RouteLongWestDune',
    'RouteMidRidge_'
)

$atmosphereChecks = @(
    'local MIN_NIGHT_BRIGHTNESS = 1.2',
    'local MAX_DAY_BRIGHTNESS = 1.82',
    'Workspace.Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(186, 164, 119))',
    'Lighting.ExposureCompensation = lerpNumber(-0.12, -0.22, dayAlpha)',
    'Lighting.FogEnd = lerpNumber(8000, 120000, dayAlpha)'
)

foreach ($check in $worldChecks) {
    Assert-Contains $hubWorldBuilder $check "world realism source"
    Assert-Contains $build $check "rebuilt world realism source"
}

foreach ($check in $atmosphereChecks) {
    Assert-Contains $hubAtmosphere $check "world atmosphere source"
    Assert-Contains $build $check "rebuilt world atmosphere source"
}

Write-Host "verify_world_realism.ps1 passed"
