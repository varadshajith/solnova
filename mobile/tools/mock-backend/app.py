from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timedelta
import random

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LoginBody(BaseModel):
    username: str
    password: str

@app.post("/api/login")
async def login(body: LoginBody):
    return {"token": "prototype_token"}

@app.get("/api/microgrids")
async def microgrids():
    return [
        {"id": "grid-001", "name": "Community A"},
        {"id": "grid-002", "name": "Community B"},
        {"id": "grid-003", "name": "Community C"},
    ]

@app.get("/api/dashboard/realtime")
async def realtime(grid_id: str = "grid-001"):
    return {
        "consumption_kW": round(random.uniform(6, 16), 1),
        "generation_kW": round(random.uniform(5, 15), 1),
        "battery_soc": random.randint(20, 100),
        # Extended telemetry
        "dc_bus_voltage_v": round(random.uniform(350, 800), 1),
        "dc_bus_current_a": round(random.uniform(10, 200), 1),
        "ac_voltage_v": round(random.uniform(210, 240), 1),
        "ac_frequency_hz": 50 if random.random() < 0.5 else 60,
        "grid_tie_connected": random.random() > 0.1,
        "equipment_temp_c": round(random.uniform(30, 70), 1),
        "solar_irradiance": random.randint(0, 1000),
        "ambient_temp_c": round(random.uniform(18, 36), 1),
        "humidity_pct": round(random.uniform(20, 90), 1),
    }

@app.get("/api/dashboard/alerts")
async def alerts(grid_id: str = "grid-001"):
    demo = [
        {"id": "a1", "message": "Load Abnormality: Unusual load increase detected.", "timestamp": datetime.utcnow().isoformat(), "severity": "warning"},
        {"id": "a2", "message": "Predictive alert: high temperature on equipment.", "timestamp": datetime.utcnow().isoformat(), "severity": "critical"},
        {"id": "a3", "message": "Renewable Performance Issue: Solar output is low.", "timestamp": datetime.utcnow().isoformat(), "severity": "info"},
    ]
    # Randomly choose subset
    n = random.randint(1, len(demo))
    return demo[:n]

@app.get("/api/dashboard/historical")
async def historical(metric: str = "consumption_kW", period: str = "1h"):
    points = []
    now = datetime.utcnow()
    if period == "1h":
        count = 60
        step = timedelta(minutes=1)
    elif period == "24h":
        count = 24
        step = timedelta(hours=1)
    elif period == "7d":
        count = 7 * 24
        step = timedelta(hours=1)
    else:
        count = 30
        step = timedelta(days=1)
    base = random.uniform(8, 12)
    for i in range(count):
        t = now - step * (count - i)
        val = base + random.uniform(-2, 2)
        if metric == "battery_soc":
            val = random.uniform(20, 100)
        points.append({"time": t.isoformat(), "value": round(val, 2)})
    return points

@app.get("/api/device/{grid_id}/list")
async def device_list(grid_id: str):
    now = datetime.utcnow()
    return [
        {"id": f"{grid_id}-inv-1", "name": "Inverter 1", "status": "connected", "last_seen": now.isoformat()},
        {"id": f"{grid_id}-bat-1", "name": "Battery Rack A", "status": "connected", "last_seen": now.isoformat()},
        {"id": f"{grid_id}-meter-1", "name": "Meter Main", "status": "disconnected", "last_seen": (now - timedelta(minutes=15)).isoformat()},
    ]

@app.get("/api/device/{device_id}/detail")
async def device_detail(device_id: str):
    return {"id": device_id, "name": device_id, "type": "inverter" if "inv" in device_id else "sensor", "firmware": "1.2.3", "status": "connected", "last_seen": datetime.utcnow().isoformat()}

@app.get("/api/device/{device_id}/telemetry")
async def device_telemetry(device_id: str):
    # Return generic k/v
    return {
        "temperature_c": round(random.uniform(30, 70), 1),
        "voltage_v": round(random.uniform(210, 240), 1),
        "current_a": round(random.uniform(5, 20), 1),
        "power_kw": round(random.uniform(2, 10), 2),
        "last_update": datetime.utcnow().isoformat(),
    }
