$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$travelRoutePath = Join-Path $root "src\ReplicatedStorage\Shared\Data\TravelRoute.lua"
$hubWorldBuilderPath = Join-Path $root "src\ServerScriptService\HubWorldBuilder.server.lua"
$battleArenaBuilderPath = Join-Path $root "src\ServerScriptService\BattleArenaBuilder.server.lua"
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

function Assert-NotContains {
    param(
        [string] $Text,
        [string] $Needle,
        [string] $Label
    )

    if ($Text.Contains($Needle)) {
        throw "Unexpected $Label`: $Needle"
    }
}

$travelRoute = Get-Content -LiteralPath $travelRoutePath -Raw
$hubWorldBuilder = Get-Content -LiteralPath $hubWorldBuilderPath -Raw
$battleArenaBuilder = Get-Content -LiteralPath $battleArenaBuilderPath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$routeChecks = @(
    'Position = Vector3.new(0, 4, 980)',
    'Position = Vector3.new(0, 4, 1620)',
    'Position = Vector3.new(920, 4, 220)',
    'Position = Vector3.new(-920, 4, -240)',
    'Position = Vector3.new(920, 4, -240)',
    'Position = Vector3.new(-920, 4, 220)',
    'Position = Vector3.new(-1090, 4, -560)',
    'Position = Vector3.new(-1090, 4, 520)'
)

$hubChecks = @(
    'local function createStylizedRidge',
    'local function createPromenadePath',
    'routeEntryPosition = Vector3.new(startPosition.X, startPosition.Y, startPosition.Z + 820)',
    'CentralFocusCourt',
    'NorthFocusBorder',
    'buildStoryCourt(geometryFolder, storyCenter)',
    'buildMannersCourt(geometryFolder, mannersCenter)',
    'buildTriviaCourt(geometryFolder, triviaCenter)',
    'buildParkourCourse(geometryFolder, parkourCenter)',
    'createPromenadePath(geometryFolder, "BadrGatePromenade"',
    'createPromenadePath(geometryFolder, "UhudGatePromenade"'
)

$uhudChecks = @(
    'local function createMesaMass',
    'createMesaMass(geometry, "UhudMainMass"',
    'createMesaMass(geometry, "BriefingUhudMass"',
    'createStoneShelf(geometry, "PassRocksWest"',
    'createStoneShelf(geometry, "BriefingPassRocksWest"'
)

$removedChecks = @(
    'HubCamels',
    'BadrFloorPlaque',
    'UhudFloorPlaque',
    'MedinaTravelPlaque',
    'DesertTravelPlaque',
    'MeccaShade_'
)

foreach ($needle in $routeChecks) {
    Assert-Contains $travelRoute $needle "travel layout source"
    Assert-Contains $build $needle "rebuilt travel layout"
}

foreach ($needle in $hubChecks) {
    Assert-Contains $hubWorldBuilder $needle "hub cleanup source"
    Assert-Contains $build $needle "rebuilt hub cleanup"
}

foreach ($needle in $uhudChecks) {
    Assert-Contains $battleArenaBuilder $needle "Uhud cleanup source"
    Assert-Contains $build $needle "rebuilt Uhud cleanup"
}

foreach ($needle in $removedChecks) {
    Assert-NotContains $hubWorldBuilder $needle "removed Kaaba clutter source"
    Assert-NotContains $build $needle "rebuilt removed Kaaba clutter"
}

Write-Host "verify_layout_cleanup.ps1 passed"
