$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$api = "http://127.0.0.1:8000"
$origin = "http://localhost:5173"

Write-Host "1/5 Checking API health..."
$health = Invoke-RestMethod -Uri "$api/api/v1/health" -Method Get
if (-not $health) { throw "Health check failed." }

Write-Host "2/5 Checking CORS preflight..."
$preflightHeaders = @{
    Origin = $origin
    "Access-Control-Request-Method" = "POST"
    "Access-Control-Request-Headers" = "content-type,idempotency-key"
}
$preflight = Invoke-WebRequest -Uri "$api/api/v1/contacts" -Method Options -Headers $preflightHeaders -UseBasicParsing
if ($preflight.StatusCode -lt 200 -or $preflight.StatusCode -ge 300) {
    throw "CORS preflight failed with status $($preflight.StatusCode)."
}

Write-Host "3/5 Creating contact..."
$key = [guid]::NewGuid().ToString()
$stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$email = "integration+$stamp@example.com"
$body = @{
    first_name = "Integration"
    last_name = "Test"
    email = $email
    phone = $null
    address = $null
    message = "Automated medrobots-platform integration test."
} | ConvertTo-Json

$headers = @{
    Origin = $origin
    "Idempotency-Key" = $key
}
$first = Invoke-RestMethod -Uri "$api/api/v1/contacts" -Method Post -Headers $headers -ContentType "application/json" -Body $body

Write-Host "4/5 Retrying with the same idempotency key..."
$second = Invoke-RestMethod -Uri "$api/api/v1/contacts" -Method Post -Headers $headers -ContentType "application/json" -Body $body

if ($first.id -and $second.id -and $first.id -ne $second.id) {
    throw "Idempotency failed: retry returned a different record."
}

Write-Host "5/5 Checking PostgreSQL persistence..."
$db = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "medrobots" }
$user = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "medrobots" }

$countRaw = docker compose exec -T db psql -U $user -d $db -tAc "SELECT COUNT(*) FROM contacts WHERE email = '$email';"
$count = [int]($countRaw.Trim())
if ($count -ne 1) {
    throw "Expected exactly one persisted contact, found $count."
}

Write-Host ""
Write-Host "PASS - frontend/API integration contract, CORS, idempotency and PostgreSQL persistence are working."
