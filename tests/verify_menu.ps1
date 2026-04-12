$BuildPath = $null
if ($args.Count -gt 0) {
    $BuildPath = $args[0]
}

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$menuPath = Join-Path $root "src\StarterPlayer\StarterPlayerScripts\MainMenu.client.lua"
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

$menu = Get-Content -LiteralPath $menuPath -Raw
$build = Get-Content -LiteralPath $buildPath -Raw

$labels = @(
    "Battle of Badr",
    "Battle of Uhud",
    "Learn About Sahabis",
    "Manners Lessons",
    "Trivia Challenge",
    "Travel To Medina",
    "Abu Bakr as-Siddiq",
    "Back To Main Menu",
    "Medina"
)

foreach ($label in $labels) {
    Assert-Contains $menu $label "menu source label"
    Assert-Contains $build $label "rebuilt place label"
}

$sourceChecks = @(
    "connectButton(closeButton, closeMenu)",
    "UserInputService.InputBegan",
    "pointInside(closeButton",
    "closeButton.Modal = true",
    "local MENU_ITEMS =",
    "local function addMenuButton",
    "showHome()",
    "function showSahabiMenu()",
    "function showMannersMenu()",
    'fireRemote("Battle", "RequestJoinBattle"',
    'fireRemote("Story", "RequestStartStory"',
    'fireRemote("Manners", "RequestLesson"',
    'fireRemote("Trivia", "RequestStartTrivia"',
    'fireRemote("Hub", "RequestTeleport"'
)

foreach ($check in $sourceChecks) {
    Assert-Contains $menu $check "menu source behavior"
}

$menuItemsIndex = $menu.IndexOf("local MENU_ITEMS =")
$showHomeIndex = $menu.IndexOf("showHome()")
$remoteIndex = $menu.IndexOf("local function getRemote")

if ($menuItemsIndex -lt 0 -or $showHomeIndex -lt 0 -or $remoteIndex -lt 0) {
    throw "Could not find expected menu sections for ordering check."
}

if ($showHomeIndex -lt $remoteIndex) {
    throw "Menu buttons should be created after the helper functions are defined."
}

Write-Host "Menu verification passed."
