$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$battleScenariosPath = Join-Path $root "src\ReplicatedStorage\Shared\Data\BattleScenarios.lua"
$battleServicePath = Join-Path $root "src\ServerScriptService\BattleService.server.lua"
$battleBotsPath = Join-Path $root "src\ServerScriptService\Modules\BattleBots.lua"
$battleLoadoutPath = Join-Path $root "src\ServerScriptService\Modules\BattleLoadout.lua"
$battleAnimationPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\BattleWeaponAnimation.client.lua"
$battleControlsPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\BattleControls.client.lua"
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

$battleScenarios = Get-Content -LiteralPath $battleScenariosPath -Raw
$battleService = Get-Content -LiteralPath $battleServicePath -Raw
$battleBots = Get-Content -LiteralPath $battleBotsPath -Raw
$battleLoadout = Get-Content -LiteralPath $battleLoadoutPath -Raw
$battleAnimation = Get-Content -LiteralPath $battleAnimationPath -Raw
$battleControls = Get-Content -LiteralPath $battleControlsPath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$scenarioChecks = @(
    "RecommendedPlayers = 60",
    "PlayersPerTeam = 30",
    "RoundDurationSeconds = 250",
    "FillEmptySlotsWithBots = false"
)

foreach ($check in $scenarioChecks) {
    Assert-Contains $battleScenarios $check "battle scenario config"
    Assert-Contains $build $check "rebuilt battle scenario config"
}

Assert-NotContains $battleScenarios "FinalBossPhase = {" "legacy Uhud boss config"
Assert-NotContains $build "FinalBossPhase = {" "rebuilt legacy Uhud boss config"

$serviceChecks = @(
    "local BattleBots = require(script.Parent.Modules.BattleBots)",
    "local function buildFormationPositions",
    "local function getDummyBotStyle",
    'BotStyle = botStyle',
    "BattleBots.Start(session)",
    "if #session.Dummies > 0 then",
    "Field strength: up to %d fighters per side",
    "Uhud now runs as a player-only mode with no filler bots"
)

foreach ($check in $serviceChecks) {
    Assert-Contains $battleService $check "battle service wiring"
    Assert-Contains $build $check "rebuilt battle service wiring"
}

$botChecks = @(
    "local BOT_ARCHER_RANGE = 124",
    "local BOT_MELEE_DAMAGE = 13",
    "local BOT_STEP_SECONDS = 0.08",
    "local function fireArrow",
    "function BattleBots.Start(session)"
)

foreach ($check in $botChecks) {
    Assert-Contains $battleBots $check "battle bot behavior"
    Assert-Contains $build $check "rebuilt battle bot behavior"
}

$loadoutChecks = @(
    "local SWORD_SWING_RANGE = 12",
    "local function findSwordTarget",
    "local function attachTrail",
    "bladeTrail.Enabled = true",
    "local arrowAlignConnection"
)

foreach ($check in $loadoutChecks) {
    Assert-Contains $battleLoadout $check "battle loadout upgrade"
    Assert-Contains $build $check "rebuilt battle loadout upgrade"
}

$animationChecks = @(
    'local Workspace = game:GetService("Workspace")',
    'local function kickCamera'
)

$controlsChecks = @(
    'if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.Q then'
)

foreach ($check in $animationChecks) {
    Assert-Contains $battleAnimation $check "battle animation upgrade"
    Assert-Contains $build $check "rebuilt client battle upgrade"
}

foreach ($check in $controlsChecks) {
    Assert-Contains $battleControls $check "battle controls upgrade"
    Assert-Contains $build $check "rebuilt client battle upgrade"
}

Write-Host "Battle upgrade verification passed."
