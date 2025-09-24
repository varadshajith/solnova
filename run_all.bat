@echo off
echo Starting SOLNOVA Prototype...

echo.
echo 1. Starting Docker services...
docker compose up -d

echo.
echo 2. Waiting for services to start...
timeout /t 5 /nobreak > nul

echo.
echo 3. Starting backend API...
start "Backend API" cmd /k "uvicorn backend.main:app --reload"

echo.
echo 4. Waiting for backend to start...
timeout /t 3 /nobreak > nul

echo.
echo 5. Starting data simulator...
start "Data Simulator" cmd /k "python simulator\data_simulator.py"

echo.
echo 6. Running verification tests...
python test_verification.py

echo.
echo 7. Starting Flutter app...
cd mobile
start "Flutter App" cmd /k "flutter run"
cd ..

echo.
echo All services started! Check the opened windows.
echo - Backend API: http://localhost:8000
echo - InfluxDB UI: http://localhost:8086
echo - Flutter app should open automatically
pause
