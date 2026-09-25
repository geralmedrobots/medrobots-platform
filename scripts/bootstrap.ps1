$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$services = Join-Path $root "services"
New-Item -ItemType Directory -Force -Path $services | Out-Null

$repos = @(
    @{ Name = "paulositecopy"; Url = "https://github.com/geralmedrobots/paulositecopy.git" },
    @{ Name = "medrobots-api"; Url = "https://github.com/geralmedrobots/medrobots-api.git" }
)

foreach ($repo in $repos) {
    $target = Join-Path $services $repo.Name

    if (Test-Path (Join-Path $target ".git")) {
        Write-Host "Updating $($repo.Name)..."
        git -C $target fetch origin
        git -C $target checkout main
        git -C $target pull --ff-only origin main
    }
    else {
        Write-Host "Cloning $($repo.Name)..."
        git clone --branch main $repo.Url $target
    }
}

Write-Host ""
Write-Host "Bootstrap complete."
Write-Host "Frontend: $services\paulositecopy"
Write-Host "Backend:  $services\medrobots-api"
