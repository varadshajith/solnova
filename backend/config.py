import os
from dataclasses import dataclass
from dotenv import load_dotenv

# Load environment variables from a .env file if present
load_dotenv()


@dataclass
class Settings:
    influx_url: str = os.getenv("INFLUX_URL", "http://localhost:8086")
    influx_org: str = os.getenv("INFLUX_ORG", "solnova")
    influx_bucket: str = os.getenv("INFLUX_BUCKET", "solnova")
    influx_token: str = os.getenv("INFLUX_TOKEN", "")

    mqtt_host: str = os.getenv("MQTT_BROKER_HOST", "localhost")
    mqtt_port: int = int(os.getenv("MQTT_BROKER_PORT", "1883"))

    api_token: str = os.getenv("API_TOKEN", "prototype_token")


settings = Settings()
