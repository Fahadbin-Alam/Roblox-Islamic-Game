$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$battleScenariosPath = Join-Path $root "src\ReplicatedStorage\Shared\Data\BattleScenarios.lua"
$battleArenaBuilderPath = Join-Path $root "src\ServerScriptService\BattleArenaBuilder.server.lua"
$battleServicePath = Join-Path $root "src\ServerScriptService\BattleService.server.lua"
$battleHudPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\BattleHud.client.lua"
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

$battleScenarios = Get-Content -LiteralPath $battleScenariosPath -Raw
$battleArenaBuilder = Get-Content -LiteralPath $battleArenaBuilderPath -Raw
$battleService = Get-Content -LiteralPath $battleServicePath -Raw
$battleHud = Get-Content -LiteralPath $battleHudPath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$scenarioChecks = @(
    'CameraName = "BriefingMap6"',
    'Qur''an 3:121 · Quran.com',
    'Qur''an 3:152-153 · Quran.com',
    'Sahih Muslim 1790a · Sunnah.com',
    'Qur''an 3:172 · Sahih al-Bukhari 4077'
)

$builderChecks = @(
    'BriefingGround',
    'BriefingUhudMass',
    'BriefingArcherShelf',
    'BriefingMedinaLead',
    'BriefingMakkahLead'
)

$serviceChecks = @(
    'local function getBriefingActor',
    'local function getBriefingActorsWithPrefix',
    'BriefingMedinaLeadAdvance',
    'BriefingMakkahLeadAdvance',
    'Reference = scene.Reference'
)

$hudChecks = @(
    'local sceneReference = Instance.new("TextLabel")',
    'sceneReference.Text = scene.Reference or ""'
)

foreach ($check in $scenarioChecks) {
    Assert-Contains $battleScenarios $check "Uhud scenario detail"
    Assert-Contains $build $check "rebuilt Uhud scenario detail"
}

foreach ($check in $builderChecks) {
    Assert-Contains $battleArenaBuilder $check "Uhud briefing geometry"
    Assert-Contains $build $check "rebuilt Uhud briefing geometry"
}

foreach ($check in $serviceChecks) {
    Assert-Contains $battleService $check "Uhud briefing animation"
    Assert-Contains $build $check "rebuilt Uhud briefing animation"
}

foreach ($check in $hudChecks) {
    Assert-Contains $battleHud $check "Uhud cutscene reference UI"
    Assert-Contains $build $check "rebuilt Uhud cutscene reference UI"
}

Write-Host "verify_uhud_intro.ps1 passed"
