import json
import threading
from typing import Optional

import paho.mqtt.client as mqtt

from .alerts_store import alerts_store
from .config import settings
from .db import write_measurement


class MQTTIngest:
    def __init__(self) -> None:
        self._client: Optional[mqtt.Client] = None
        self._thread: Optional[threading.Thread] = None

    def _on_connect(self, client, userdata, flags, reason_code, properties=None):
        client.subscribe("microgrid/data")
        client.subscribe("microgrid/alerts")

    def _on_message(self, client, userdata, msg):
        topic = msg.topic
        try:
            payload = json.loads(msg.payload.decode("utf-8"))
        except Exception:
            return
        if topic == "microgrid/data":
            try:
                write_measurement(payload)
            except Exception:
                pass
        elif topic == "microgrid/alerts":
            message = payload.get("message")
            timestamp = payload.get("timestamp")
            if message and timestamp:
                alerts_store.add(message=message, timestamp=timestamp)

    def start(self) -> None:
        if self._client is not None:
            return
        self._client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message
        self._client.connect(settings.mqtt_host, settings.mqtt_port, keepalive=60)
        self._thread = threading.Thread(target=self._client.loop_forever, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        if self._client is not None:
            self._client.disconnect()
            self._client = None


ingest = MQTTIngest()
