from collections import deque
from dataclasses import dataclass
from datetime import datetime
from typing import Deque, Dict, List


@dataclass
class Alert:
    id: str
    message: str
    timestamp: str
    severity: str = "warning"


class AlertsStore:
    def __init__(self, maxlen: int = 1000) -> None:
        self._alerts: Deque[Alert] = deque(maxlen=maxlen)

    def add(self, message: str, timestamp: str) -> Alert:
        alert_id = f"alert-{int(datetime.fromisoformat(timestamp.replace('Z', '+00:00')).timestamp())}-{len(self._alerts)}"
        alert = Alert(id=alert_id, message=message, timestamp=timestamp)
        self._alerts.appendleft(alert)
        return alert

    def list(self) -> List[Dict]:
        return [alert.__dict__ for alert in list(self._alerts)]


alerts_store = AlertsStore()
