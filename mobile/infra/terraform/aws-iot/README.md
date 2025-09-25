# AWS IoT Core + Kinesis (Terraform)

This module provisions the minimum AWS resources to ingest MQTT messages from devices and route them into Kinesis for downstream ETL (Lambda/Kinesis). It creates:

- IoT Thing Type (for organizing devices)
- IoT Policy for devices (least-privilege to publish telemetry and subscribe to alerts)
- Kinesis Data Streams (telemetry and alerts)
- IoT Topic Rules to route:
  - microgrid/{grid_id}/device/{device_id}/telemetry → Kinesis (telemetry stream)
  - microgrid/{grid_id}/alerts → Kinesis (alerts stream)
- IAM Role for topic rules to write to Kinesis

Prerequisites
- Terraform v1.5+
- AWS account credentials locally (AWS_PROFILE or environment variables)

Usage

1) Configure variables (optional)
- See variables.tf for defaults. You can override via a tfvars file or CLI flags.

2) Initialize and apply
- terraform init
- terraform plan -out tf.plan
- terraform apply tf.plan

3) Register a device (example via AWS CLI)
- Create a Thing:
  aws iot create-thing --thing-name device-001

- Create keys and certificate (saves credentials locally):
  aws iot create-keys-and-certificate \
    --set-as-active \
    --certificate-pem-outfile cert.pem \
    --public-key-outfile public.key \
    --private-key-outfile private.key

- Attach the device policy and Thing principal (replace names from Terraform outputs):
  aws iot attach-policy --policy-name <device_policy_name_output> --target <certificate_arn>

  aws iot attach-thing-principal \
    --thing-name device-001 \
    --principal <certificate_arn>

4) MQTT topics (for your device)
- Telemetry publish topic:
  microgrid/<grid_id>/device/<device_id>/telemetry

- Alerts topic (backend or simulator publishes):
  microgrid/<grid_id>/alerts

5) Test publish (using mosquitto_pub — replace paths; requires TLS config)
- mosquitto_pub -h <your-iot-endpoint> -p 8883 \
  --cafile <AmazonRootCA1.pem> \
  --cert cert.pem \
  --key private.key \
  -t microgrid/grid-001/device/device-001/telemetry \
  -m '{"consumption_kW":10.5,"generation_kW":9.8,"battery_soc":75}'

Notes
- The IoT policy uses IoT policy variables to scope publish permission to the clientId/deviceId.
- You can later attach a Lambda (ETL) to consume from Kinesis and write to InfluxDB/DynamoDB.
- To destroy: terraform destroy (this will delete streams and rules).
