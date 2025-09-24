import json
import os
import random
import time
from datetime import datetime, timezone

import paho.mqtt.client as mqtt

MQTT_BROKER_HOST = os.getenv("MQTT_BROKER_HOST", "localhost")
MQTT_BROKER_PORT = int(os.getenv("MQTT_BROKER_PORT", "1883"))
PUBLISH_INTERVAL_SECONDS = int(os.getenv("SIMULATOR_INTERVAL_SECONDS", "5"))

TOPIC_DATA = "microgrid/data"
TOPIC_ALERTS = "microgrid/alerts"


def generate_payload():
    now = datetime.now(timezone.utc).isoformat()
    payload = {
        "timestamp": now,
        "live_power_consumption": round(random.uniform(5.0, 15.0), 2),
        "live_generation": round(random.uniform(6.0, 16.0), 2),
        "battery_soc": random.randint(20, 100),
        "temp_equipment": round(random.uniform(30.0, 70.0), 2),
        "solar_irradiance": random.randint(0, 100),
    }
    return payload


def detect_alerts(payload):
    alerts = []
    if payload["live_power_consumption"] > 14.0:
        alerts.append("Load Abnormality: Unusual load increase detected.")
    if payload["temp_equipment"] > 60.0:
        alerts.append("Predictive alert: high temperature on equipment.")
    if payload["live_generation"] < 7.0 and payload["solar_irradiance"] > 50:
        alerts.append("Renewable Performance Issue: Solar output is low.")
    return alerts


def main():
    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.connect(MQTT_BROKER_HOST, MQTT_BROKER_PORT, keepalive=60)
    client.loop_start()

    try:
        while True:
            payload = generate_payload()
            client.publish(TOPIC_DATA, json.dumps(payload), qos=0, retain=False)

            for message in detect_alerts(payload):
                alert = {
                    "timestamp": payload["timestamp"],
                    "message": message,
                }
                client.publish(TOPIC_ALERTS, json.dumps(alert), qos=0, retain=False)

            time.sleep(PUBLISH_INTERVAL_SECONDS)
    except KeyboardInterrupt:
        pass
    finally:
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    main()
