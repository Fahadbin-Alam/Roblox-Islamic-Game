$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$battleAnimationLibraryPath = Join-Path $root "src\ReplicatedStorage\Shared\Config\BattleAnimationLibrary.lua"
$battleWeaponAnimationPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\BattleWeaponAnimation.client.lua"
$battleHudPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\BattleHud.client.lua"
$battleScenariosPath = Join-Path $root "src\ReplicatedStorage\Shared\Data\BattleScenarios.lua"
$hubWorldBuilderPath = Join-Path $root "src\ServerScriptService\HubWorldBuilder.server.lua"
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

$battleAnimationLibrary = Get-Content -LiteralPath $battleAnimationLibraryPath -Raw
$battleWeaponAnimation = Get-Content -LiteralPath $battleWeaponAnimationPath -Raw
$battleHud = Get-Content -LiteralPath $battleHudPath -Raw
$battleScenarios = Get-Content -LiteralPath $battleScenariosPath -Raw
$hubWorldBuilder = Get-Content -LiteralPath $hubWorldBuilderPath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$libraryChecks = @(
    'local BattleAnimationLibrary = {',
    'DrawLoop = {',
    'function BattleAnimationLibrary.HasAnimation(entry): boolean'
)

$weaponChecks = @(
    'local BattleAnimationLibrary = require(Shared.Config.BattleAnimationLibrary)',
    'local function getAnimatorFromTool(tool: Tool): Animator?',
    'local function playConfiguredTrack(tool: Tool, key: string, entry)',
    'playConfiguredTrack(tool, "SwordSlash", swordConfig.Slash)',
    'playConfiguredTrack(tool, "BowDrawLoop", bowConfig.DrawLoop)'
)

$hudChecks = @(
    'local function resolveCameraPosition(desiredPosition: Vector3, lookTarget: Vector3): Vector3',
    'local function moveCameraThroughScene(camera: Camera, scene, duration: number, token: number)',
    'local drift = scene.CameraDrift',
    'camera.CFrame = CFrame.lookAt(driftedPosition, driftedLook)'
)

$scenarioChecks = @(
    'CameraDrift = Vector3.new(10, 1, -4)',
    'CameraDrift = Vector3.new(14, 2, -8)',
    'FieldOfView = 61,',
    'FieldOfView = 57,'
)

$kaabaChecks = @(
    'local insetSize',
    'bodyHalfX = 38',
    'bodyHalfZ = 31',
    'KaabaShadowHemFront'
)

$arenaChecks = @(
    'UhudViewShelfWest',
    'camera4 = BuildUtils.CreateTeleportAnchor(cameras, "Scene4", center + Vector3.new(84, 42, 18))',
    'camera5 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap5", center + Vector3.new(90, 44, 10))'
)

foreach ($check in $libraryChecks) {
    Assert-Contains $battleAnimationLibrary $check "battle animation library"
    Assert-Contains $build $check "rebuilt battle animation library"
}

foreach ($check in $weaponChecks) {
    Assert-Contains $battleWeaponAnimation $check "battle weapon animation polish"
    Assert-Contains $build $check "rebuilt battle weapon animation polish"
}

foreach ($check in $hudChecks) {
    Assert-Contains $battleHud $check "battle cinematic polish"
    Assert-Contains $build $check "rebuilt battle cinematic polish"
}

foreach ($check in $scenarioChecks) {
    Assert-Contains $battleScenarios $check "battle scene drift config"
    Assert-Contains $build $check "rebuilt battle scene drift config"
}

foreach ($check in $kaabaChecks) {
    Assert-Contains $hubWorldBuilder $check "Kaaba polish source"
    Assert-Contains $build $check "rebuilt Kaaba polish source"
}

foreach ($check in $arenaChecks) {
    Assert-Contains $build $check "rebuilt Uhud camera polish"
}

Write-Host "verify_presentation_polish.ps1 passed"
