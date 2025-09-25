import base64
import json
import os
import time
from datetime import datetime
from urllib import request, parse
import boto3

DDB = boto3.resource('dynamodb')

INFLUX_URL = os.environ.get('INFLUX_URL', '')  # e.g., https://us-east-1-1.aws.cloud2.influxdata.com
INFLUX_ORG = os.environ.get('INFLUX_ORG', '')
INFLUX_BUCKET = os.environ.get('INFLUX_BUCKET', '')
INFLUX_TOKEN = os.environ.get('INFLUX_TOKEN', '')
ALERTS_TABLE = os.environ.get('ALERTS_TABLE', '')

def write_influx_line(measurement: str, fields: dict, tags: dict | None, ts_ns: int):
    if not (INFLUX_URL and INFLUX_ORG and INFLUX_BUCKET and INFLUX_TOKEN):
        return  # not configured
    # Build line protocol
    def esc(s):
        return str(s).replace(' ', '\\ ').replace(',', '\\,')
    tag_str = ''
    if tags:
        tag_str = ',' + ','.join(f"{esc(k)}={esc(v)}" for k, v in tags.items())
    field_parts = []
    for k, v in fields.items():
        if isinstance(v, (int, float)):
            field_parts.append(f"{esc(k)}={v}")
        else:
            field_parts.append(f"{esc(k)}=\"{str(v).replace('\\', '\\\\').replace('"', '\\"')}\"")
    field_str = ','.join(field_parts)
    line = f"{measurement}{tag_str} {field_str} {ts_ns}"
    data = line.encode('utf-8')
    url = f"{INFLUX_URL}/api/v2/write?org={parse.quote(INFLUX_ORG)}&bucket={parse.quote(INFLUX_BUCKET)}&precision=ns"
    req = request.Request(url, data=data, method='POST')
    req.add_header('Authorization', f'Token {INFLUX_TOKEN}')
    req.add_header('Content-Type', 'text/plain; charset=utf-8')
    try:
        with request.urlopen(req, timeout=3) as resp:
            _ = resp.read()
    except Exception as e:
        print('Influx write error:', e)


def put_alert_ddb(alert: dict):
    if not ALERTS_TABLE:
        return
    table = DDB.Table(ALERTS_TABLE)
    # Ensure an id
    if 'id' not in alert:
        alert['id'] = f"alert-{int(time.time()*1000)}"
    item = {
        'alert_id': str(alert.get('id')),
        'message': str(alert.get('message', '')),
        'severity': str(alert.get('severity', 'info')),
        'grid_id': str(alert.get('grid_id', 'unknown')),
        'device_id': str(alert.get('device_id', '')),
        'timestamp': alert.get('timestamp') or datetime.utcnow().isoformat(),
        'raw': json.dumps(alert),
    }
    table.put_item(Item=item)


def handler(event, context):
    # Kinesis event
    for rec in event.get('Records', []):
        payload = base64.b64decode(rec['kinesis']['data'])
        try:
            data = json.loads(payload)
        except Exception:
            print('Non-JSON payload, skipping')
            continue
        # Heuristic: if looks like alert -> DDB; else -> Influx
        if isinstance(data, dict) and ('message' in data or data.get('type') == 'alert'):
            put_alert_ddb(data)
        else:
            # Write as measurement=telemetry
            ts_ns = int(time.time() * 1e9)
            fields = {}
            tags = {}
            for k, v in data.items() if isinstance(data, dict) else []:
                # Separate some tags if present
                if k in ('grid_id', 'device_id'):
                    tags[k] = v
                elif isinstance(v, (int, float, str, bool)):
                    fields[k] = v
            if fields:
                write_influx_line('telemetry', fields, tags, ts_ns)
    return {'status': 'ok'}
