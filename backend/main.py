from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict

from .config import settings
from .db import query_latest, query_historical
from .alerts_store import alerts_store
from .mqtt_client import ingest

app = FastAPI(title="SOLNOVA Prototype API")


# Global exception handler to surface errors during development
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(status_code=503, content={"detail": f"{type(exc).__name__}: {exc}"})

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=[],  # Use regex below for localhost during development
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,  # No cookies; simplifies CORS for web
    allow_methods=["*"],
    allow_headers=["*"]
)


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    token: str


@app.on_event("startup")
def startup_event():
    ingest.start()


@app.post("/api/login", response_model=TokenResponse)
def login(body: LoginRequest):
    # Basic input validation
    if not body.username or not body.password:
        raise HTTPException(status_code=400, detail="Username and password required")
    
    # Simple hardcoded auth for prototype
    if body.username == "user" and body.password == "password":
        return TokenResponse(token=settings.api_token)
    raise HTTPException(status_code=401, detail="Invalid credentials")


def require_token(authorization: Optional[str] = Header(default=None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing token")
    token = authorization.replace("Bearer ", "").strip()
    if token != settings.api_token:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.get("/api/dashboard/realtime")
def get_realtime(_: None = Depends(require_token)):
    try:
        latest = query_latest()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Realtime data unavailable: {type(e).__name__}: {e}")
    if not latest:
        raise HTTPException(status_code=404, detail="No data available")
    return latest


@app.get("/api/dashboard/alerts")
def get_alerts(_: None = Depends(require_token)) -> List[Dict]:
    return alerts_store.list()


@app.get("/api/dashboard/historical")
def get_historical(metric: str, period: str, _: None = Depends(require_token)):
    # Input validation
    valid_metrics = ["consumption_kW", "generation_kW", "battery_soc"]
    if metric not in valid_metrics:
        raise HTTPException(status_code=400, detail=f"Invalid metric. Must be one of: {valid_metrics}")
    
    valid_periods = ["1h", "24h", "7d", "30d"]
    if period not in valid_periods:
        raise HTTPException(status_code=400, detail=f"Invalid period. Must be one of: {valid_periods}")
    
    try:
        return query_historical(metric=metric, period=period)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Historical data unavailable: {type(e).__name__}: {e}")
