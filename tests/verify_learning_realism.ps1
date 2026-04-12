$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$hubWorldBuilderPath = Join-Path $root "src\ServerScriptService\HubWorldBuilder.server.lua"
$mannersLessonsPath = Join-Path $root "src\ReplicatedStorage\Shared\Data\MannersLessons.lua"
$companionStoriesPath = Join-Path $root "src\ReplicatedStorage\Shared\Data\CompanionStories.lua"
$battleServicePath = Join-Path $root "src\ServerScriptService\BattleService.server.lua"
$battleScenariosPath = Join-Path $root "src\ReplicatedStorage\Shared\Data\BattleScenarios.lua"
$battleArenaBuilderPath = Join-Path $root "src\ServerScriptService\BattleArenaBuilder.server.lua"
$battleBotsPath = Join-Path $root "src\ServerScriptService\Modules\BattleBots.lua"
$mannersHudPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\MannersHud.client.lua"
$storyHudPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\StoryHud.client.lua"
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

$hubWorldBuilder = Get-Content -LiteralPath $hubWorldBuilderPath -Raw
$mannersLessons = Get-Content -LiteralPath $mannersLessonsPath -Raw
$companionStories = Get-Content -LiteralPath $companionStoriesPath -Raw
$battleService = Get-Content -LiteralPath $battleServicePath -Raw
$battleScenarios = Get-Content -LiteralPath $battleScenariosPath -Raw
$battleArenaBuilder = Get-Content -LiteralPath $battleArenaBuilderPath -Raw
$battleBots = Get-Content -LiteralPath $battleBotsPath -Raw
$mannersHud = Get-Content -LiteralPath $mannersHudPath -Raw
$storyHud = Get-Content -LiteralPath $storyHudPath -Raw
$battleHud = Get-Content -LiteralPath $battleHudPath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$hubChecks = @(
    'createLayeredHaramSideFacade(district, "NorthModernFacade"',
    'createModernHaramDetailLayer(district, center)',
    'MakkahHotelNorthWest',
    'MakkahNorthCentralMinaret'
)

$lessonChecks = @(
    'Qur''an: Surah At-Tawbah 9:119',
    'Sahih Muslim 2607c',
    'Qur''an: Surah Al-Isra'' 17:23-24',
    'Sahih al-Bukhari 5971',
    'Sahih al-Bukhari 6013',
    'Sahih al-Bukhari 2682',
    'Riyad as-Salihin 308'
)

$storyChecks = @(
    'Sahih al-Bukhari 3653',
    'Sahih Muslim 418a',
    'Jami` at-Tirmidhi 3689',
    'Jami` at-Tirmidhi 3853',
    'Sahih al-Bukhari 4160-4161',
    'Qur''an 33:23'
)

$battleChecks = @(
    'InitialHumanCounts',
    'getHumanLivingCount',
    'players still decide the round',
    'if targetEntry.IsCommander then',
    'if candidate.IsCommander then',
    'BOT_STEP_SECONDS = 0.08'
)

$uhudChecks = @(
    'Qur''an 3:121',
    'Qur''an 3:152',
    'Qur''an 3:153',
    'Qur''an 3:169-172',
    'Qur''an 3:172',
    'Sunan Abi Dawud 2662',
    'Sahih Muslim 1789',
    'Sahih Muslim 1790a',
    'Sahih al-Bukhari 4077',
    'Sahih al-Bukhari 4422',
    'FillEmptySlotsWithBots = false',
    'BriefingUhudMass',
    'BriefingMedinaLead',
    'local camera6 = BuildUtils.CreateTeleportAnchor(cameras, "Scene6"',
    'LastStandShelfTerrain',
    'Steadfast Ground',
    'UhudFinalStandStory'
)

$hudChecks = @(
    'AutomaticCanvasSize = Enum.AutomaticSize.Y',
    'local function getLineDuration',
    'REFERENCE_SPEAKER_COLOR',
    'local function tweenSceneText',
    'sceneTextPlate',
    'local sceneReference = Instance.new("TextLabel")',
    'local function setCoreGuiVisibility',
    'local function setCutscenePostProcessing'
)

foreach ($needle in $hubChecks) {
    Assert-Contains $hubWorldBuilder $needle "hub world source"
    Assert-Contains $build $needle "rebuilt hub marker"
}

foreach ($needle in $lessonChecks) {
    Assert-Contains $mannersLessons $needle "manners lesson source"
    Assert-Contains $build $needle "rebuilt lesson text"
}

foreach ($needle in $storyChecks) {
    Assert-Contains $companionStories $needle "story source"
    Assert-Contains $build $needle "rebuilt story text"
}

foreach ($needle in $battleChecks) {
    $source = if ($battleBots.Contains($needle)) { $battleBots } else { $battleService }
    Assert-Contains $source $needle "battle source"
}

foreach ($needle in $uhudChecks) {
    $source = if ($battleScenarios.Contains($needle)) {
        $battleScenarios
    } elseif ($battleArenaBuilder.Contains($needle)) {
        $battleArenaBuilder
    } else {
        $battleService
    }
    Assert-Contains $source $needle "uhud source"
    Assert-Contains $build $needle "rebuilt uhud text"
}

if ($battleScenarios.Contains('FinalBossPhase = {') -or $build.Contains('FinalBossPhase = {')) {
    throw "Uhud still contains the removed final boss phase."
}

foreach ($needle in $hudChecks) {
    $source = if ($mannersHud.Contains($needle)) {
        $mannersHud
    } elseif ($storyHud.Contains($needle)) {
        $storyHud
    } else {
        $battleHud
    }
    Assert-Contains $source $needle "hud source"
}

Write-Host "verify_learning_realism.ps1 passed"
