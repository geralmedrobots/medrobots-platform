$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path ".\services\paulositecopy\.git") -or -not (Test-Path ".\services\medrobots-api\.git")) {
    Write-Host "Application repositories are missing. Running bootstrap..."
    & "$PSScriptRoot\bootstrap.ps1"
}

if (-not (Test-Path ".\.env")) {
    Copy-Item ".\.env.example" ".\.env"
    Write-Host "Created .env from .env.example"
}

docker compose up --build -d

Write-Host ""
Write-Host "Waiting for API health..."
$deadline = (Get-Date).AddMinutes(2)
do {
    Start-Sleep -Seconds 2
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 3
        if ($health) { break }
    }
    catch {
        if ((Get-Date) -gt $deadline) { throw "API did not become healthy within 2 minutes." }
    }
} while ($true)

Write-Host "Platform is running."
Write-Host "Frontend: http://localhost:5173"
Write-Host "API:      http://127.0.0.1:8000"
