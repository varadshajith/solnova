from typing import Optional
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

from .config import settings


_client: Optional[InfluxDBClient] = None
_write_api = None


def get_client() -> InfluxDBClient:
    global _client, _write_api
    if _client is None:
        _client = InfluxDBClient(url=settings.influx_url, token=settings.influx_token, org=settings.influx_org)
        _write_api = _client.write_api(write_options=SYNCHRONOUS)
    return _client


def write_measurement(payload: dict) -> None:
    get_client()
    point = (
        Point("microgrid")
        .field("consumption_kW", float(payload.get("live_power_consumption", 0)))
        .field("generation_kW", float(payload.get("live_generation", 0)))
        .field("battery_soc", int(payload.get("battery_soc", 0)))
    )
    _write_api.write(bucket=settings.influx_bucket, record=point)


def query_latest() -> Optional[dict]:
    client = get_client()
    query_api = client.query_api()
    q = f"""
from(bucket: "{settings.influx_bucket}")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "microgrid")
  |> last()
"""
    tables = query_api.query(q, org=settings.influx_org)
    result = {"consumption_kW": None, "generation_kW": None, "battery_soc": None}
    for table in tables:
        for record in table.records:
            if record.get_field() in result:
                result[record.get_field()] = record.get_value()
    if any(v is None for v in result.values()):
        return None
    return result


def query_historical(metric: str, period: str):
    if metric not in {"consumption_kW", "generation_kW", "battery_soc"}:
        return []
    client = get_client()
    query_api = client.query_api()
    q = f"""
from(bucket: "{settings.influx_bucket}")
  |> range(start: -{period})
  |> filter(fn: (r) => r._measurement == "microgrid")
  |> filter(fn: (r) => r._field == "{metric}")
  |> keep(columns: ["_time", "_value"]) 
"""
    tables = query_api.query(q, org=settings.influx_org)
    points = []
    for table in tables:
        for record in table.records:
            points.append({"time": record.get_time().isoformat(), "value": record.get_value()})
    return points
