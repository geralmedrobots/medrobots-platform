# Med Robots Platform

Integration and deployment layer for the Med Robots web platform.

This repository does **not** duplicate application code. It orchestrates:

- Frontend: https://github.com/geralmedrobots/paulositecopy
- API: https://github.com/geralmedrobots/medrobots-api
- PostgreSQL

## Quick start

### 1. Bootstrap the application repositories

```powershell
./scripts/bootstrap.ps1
```

This clones or updates both repositories into `services/`.

### 2. Create local environment file

```powershell
Copy-Item .env.example .env
```

### 3. Start the integrated stack

```powershell
./scripts/start.ps1
```

Services:

- Frontend: http://localhost:5173
- API: http://127.0.0.1:8000
- API health: http://127.0.0.1:8000/api/v1/health

### 4. Run the integration test

```powershell
./scripts/test-integration.ps1
```

The test verifies:

1. API health.
2. CORS preflight.
3. Contact form POST.
4. Idempotent retry with the same key.
5. Persistence of the contact row in PostgreSQL.

### 5. Stop the stack

```powershell
./scripts/stop.ps1
```

## Architecture

```text
Browser
  |
  +--> React/Vite frontend :5173
  |       |
  |       +--> POST /api/v1/contacts
  |
  +--> FastAPI :8000
          |
          +--> PostgreSQL :5432 (internal Docker network)
```

The platform repository owns orchestration only. Application changes remain in their source repositories.

## Requirements

- Git
- Docker Desktop with Docker Compose v2
- PowerShell 5.1+ or PowerShell 7

Node.js and Python do not need to be installed locally for the Docker workflow.
