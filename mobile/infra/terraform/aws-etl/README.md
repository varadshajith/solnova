# AWS ETL Lambda (Terraform)

This module provisions a Python Lambda that consumes records from Kinesis streams and routes:
- Telemetry records → InfluxDB Cloud (HTTP write API)
- Alerts records → DynamoDB alerts table

Inputs
- aws_region, aws_profile (optional)
- project, environment
- telemetry_stream_name, alerts_stream_name (must match streams created in aws-iot module)
- dynamodb_alerts_table_name (optional; created here if it does not exist)
- Influx env (set in Lambda environment): INFLUX_URL, INFLUX_ORG, INFLUX_BUCKET, INFLUX_TOKEN

Apply
- terraform init
- terraform plan -var "telemetry_stream_name=<name>" -var "alerts_stream_name=<name>" -out tf.plan
- terraform apply tf.plan

Notes
- Lambda uses stdlib urllib to call InfluxDB HTTP write API (no external deps).
- Make sure to configure Lambda environment variables for Influx; do not hardcode secrets.
- You can extend the DynamoDB schema and add GSIs as needed.
