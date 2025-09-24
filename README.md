# SOLNOVA Prototype

This repository contains a functional prototype of a microgrid monitoring system per `product_spec.md`.

## Prerequisites
- Python 3.10+
- Docker Desktop
- Flutter SDK (for the mobile app)

## Quick Start

### 1. Setup Environment
```powershell
# Create and activate virtual environment
py -3 -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

### 2. Start Services
```powershell
# Start InfluxDB and Mosquitto
docker compose up -d

# Start backend API
uvicorn backend.main:app --reload

# Start data simulator (in new terminal)
python .\simulator\data_simulator.py
```

### 3. Run Mobile App
```powershell
cd mobile
flutter pub get
flutter run
```

### 4. Verify Everything Works
```powershell
# Run verification tests
python test_verification.py
```

## Detailed Setup

### Backend API
- **URL**: http://localhost:8000
- **Docs**: http://localhost:8000/docs
- **Endpoints**:
  - `POST /api/login` - Authentication
  - `GET /api/dashboard/realtime` - Live KPIs
  - `GET /api/dashboard/alerts` - Active alerts
  - `GET /api/dashboard/historical` - Historical data

### Services
- **InfluxDB**: http://localhost:8086 (admin/adminpassword)
- **Mosquitto MQTT**: tcp://localhost:1883

### Environment Variables
Create `.env` file (optional, defaults work for local development):
```env
INFLUX_URL=http://localhost:8086
INFLUX_ORG=solnova
INFLUX_BUCKET=solnova
INFLUX_TOKEN=your-token-here
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
SIMULATOR_INTERVAL_SECONDS=5
```

## Project Structure
- `backend/` — FastAPI service with MQTT ingest and InfluxDB
- `simulator/` — Data simulator script
- `mobile/` — Flutter app with login and dashboard
- `test_verification.py` — Verification tests

## Security Features
- Input validation on all endpoints
- Token-based authentication
- CORS configuration for mobile app
- Environment variable configuration
- No hardcoded secrets in code

## Troubleshooting
1. **Backend won't start**: Check if InfluxDB is running (`docker compose up -d`)
2. **No data in dashboard**: Ensure simulator is running
3. **Flutter build errors**: Run `flutter clean && flutter pub get`
4. **API connection issues**: Check CORS settings and network connectivity

## Notes
- Follow `rules.md`. The spec is the single source of truth.
- Never commit secrets. Use `.env` for local configuration.
- This is a prototype - not production-ready.
