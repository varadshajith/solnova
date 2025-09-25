# Mock Backend (FastAPI)

A lightweight mock backend to demo the mobile app without full cloud infra.

Endpoints
- POST /api/login → {"token":"prototype_token"}
- GET /api/microgrids → list of demo grids
- GET /api/dashboard/realtime → KPI + extended telemetry for a selected grid
- GET /api/dashboard/alerts → demo alerts list
- GET /api/dashboard/historical?metric=&period= → time series points
- GET /api/device/{grid_id}/list → devices for a grid
- GET /api/device/{device_id}/detail → device metadata
- GET /api/device/{device_id}/telemetry → key/value telemetry snapshot

Quick start (Windows PowerShell)

- cd tools/mock-backend
- py -m venv .venv
- .venv\\Scripts\\Activate.ps1
- pip install -r requirements.txt
- uvicorn app:app --reload --port 8000

Set the mobile app to use API_BASE=http://localhost:8000 (the default already).
