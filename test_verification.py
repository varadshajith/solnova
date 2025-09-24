#!/usr/bin/env python3
"""
Verification tests for SOLNOVA prototype per Phase 8.
Run after starting backend and simulator.
"""
import json
import time
import requests
from typing import Dict, Any


API_BASE = "http://localhost:8000"


def test_login() -> str:
    """Test login endpoint returns token."""
    print("Testing login endpoint...")
    resp = requests.post(
        f"{API_BASE}/api/login",
        json={"username": "user", "password": "password"}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "token" in data
    token = data["token"]
    print(f"✓ Login successful, token: {token[:20]}...")
    return token


def test_realtime_endpoint(token: str) -> None:
    """Test realtime endpoint returns KPIs."""
    print("Testing realtime endpoint...")
    resp = requests.get(
        f"{API_BASE}/api/dashboard/realtime",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 200
    data = resp.json()
    required_fields = ["consumption_kW", "generation_kW", "battery_soc"]
    for field in required_fields:
        assert field in data, f"Missing field: {field}"
        assert isinstance(data[field], (int, float)), f"Invalid type for {field}"
    print("✓ Realtime endpoint working")


def test_alerts_endpoint(token: str) -> None:
    """Test alerts endpoint returns list."""
    print("Testing alerts endpoint...")
    resp = requests.get(
        f"{API_BASE}/api/dashboard/alerts",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list), "Alerts should be a list"
    print(f"✓ Alerts endpoint working, {len(data)} alerts")


def test_historical_endpoint(token: str) -> None:
    """Test historical endpoint returns data points."""
    print("Testing historical endpoint...")
    resp = requests.get(
        f"{API_BASE}/api/dashboard/historical?metric=consumption_kW&period=24h",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list), "Historical data should be a list"
    if data:  # May be empty if no data yet
        for point in data:
            assert "time" in point and "value" in point
    print("✓ Historical endpoint working")


def test_unauthorized_access() -> None:
    """Test endpoints require authentication."""
    print("Testing unauthorized access...")
    resp = requests.get(f"{API_BASE}/api/dashboard/realtime")
    assert resp.status_code == 401
    resp = requests.get(f"{API_BASE}/api/dashboard/alerts")
    assert resp.status_code == 401
    print("✓ Authentication required")


def test_invalid_credentials() -> None:
    """Test invalid login credentials."""
    print("Testing invalid credentials...")
    resp = requests.post(
        f"{API_BASE}/api/login",
        json={"username": "wrong", "password": "wrong"}
    )
    assert resp.status_code == 401
    print("✓ Invalid credentials rejected")


def main():
    """Run all verification tests."""
    print("=== SOLNOVA Prototype Verification Tests ===\n")
    
    try:
        # Test authentication
        token = test_login()
        test_invalid_credentials()
        test_unauthorized_access()
        
        # Test protected endpoints
        test_realtime_endpoint(token)
        test_alerts_endpoint(token)
        test_historical_endpoint(token)
        
        print("\n✅ All tests passed! Prototype is working correctly.")
        print("\nNext steps:")
        print("1. Start Flutter app: cd mobile && flutter run")
        print("2. Login with user/password")
        print("3. Verify dashboard shows real-time data and alerts")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        print("\nTroubleshooting:")
        print("1. Ensure backend is running: uvicorn backend.main:app --reload")
        print("2. Ensure simulator is running: python simulator/data_simulator.py")
        print("3. Ensure Docker services are up: docker compose up -d")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
