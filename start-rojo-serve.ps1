$ErrorActionPreference = "Stop"

$localRojoExe = Join-Path $PSScriptRoot ".tools\rojo\rojo.exe"
$projectFile = Join-Path $PSScriptRoot "default.project.json"

if (Test-Path $localRojoExe) {
    $rojoExe = $localRojoExe
} else {
    $rojoExe = "rojo"
}

if (-not (Test-Path $projectFile)) {
    throw "Project file was not found at $projectFile"
}

Write-Host "Starting Rojo serve for $projectFile" -ForegroundColor Cyan
Write-Host "If the server starts correctly, Studio can connect to localhost on the port Rojo prints below." -ForegroundColor Yellow

& $rojoExe serve $projectFile
