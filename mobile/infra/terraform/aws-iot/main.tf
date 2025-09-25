data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# IoT Thing Type (for organizing devices)
resource "aws_iot_thing_type" "device_type" {
  name = "${local.name_prefix}-device"
}

# Kinesis streams for telemetry and alerts
resource "aws_kinesis_stream" "telemetry" {
  name             = "${local.name_prefix}-telemetry"
  shard_count      = 1
  retention_period = 24
}

resource "aws_kinesis_stream" "alerts" {
  name             = "${local.name_prefix}-alerts"
  shard_count      = 1
  retention_period = 24
}

# IAM Role for IoT Topic Rules to put records into Kinesis
resource "aws_iam_role" "iot_rule_role" {
  name = "${local.name_prefix}-iot-rule-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "iot.amazonaws.com" },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_rule_to_kinesis" {
  name = "${local.name_prefix}-iot-rule-kinesis-policy"
  role = aws_iam_role.iot_rule_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["kinesis:PutRecord", "kinesis:PutRecords"],
        Resource = [
          aws_kinesis_stream.telemetry.arn,
          aws_kinesis_stream.alerts.arn
        ]
      }
    ]
  })
}

# IoT Topic Rule: telemetry → Kinesis
resource "aws_iot_topic_rule" "telemetry_to_kinesis" {
  name        = "${local.name_prefix}-telemetry-to-kinesis"
  description = "Route telemetry MQTT to Kinesis"
  enabled     = true
  sql         = "SELECT * FROM 'microgrid/+\/device/+\/telemetry'"
  sql_version = "2016-03-23"

  kinesis {
    role_arn    = aws_iam_role.iot_rule_role.arn
    stream_name = aws_kinesis_stream.telemetry.name
    partition_key = "${uuid()}"
  }
}

# IoT Topic Rule: alerts → Kinesis
resource "aws_iot_topic_rule" "alerts_to_kinesis" {
  name        = "${local.name_prefix}-alerts-to-kinesis"
  description = "Route alerts MQTT to Kinesis"
  enabled     = true
  sql         = "SELECT * FROM 'microgrid/+\/alerts'"
  sql_version = "2016-03-23"

  kinesis {
    role_arn    = aws_iam_role.iot_rule_role.arn
    stream_name = aws_kinesis_stream.alerts.name
    partition_key = "${uuid()}"
  }
}

# IoT Device Policy (least-privilege)
# - Allow device to publish only to its telemetry topic (clientId used in topic)
# - Allow device to subscribe to shared alerts topic
resource "aws_iot_policy" "device_policy" {
  name = "${local.name_prefix}-device-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["iot:Connect"],
        "Resource": ["*"]
      },
      {
        "Effect": "Allow",
        "Action": ["iot:Publish"],
        "Resource": [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/microgrid/*/device/${iot:ClientId}/telemetry"
        ]
      },
      {
        "Effect": "Allow",
        "Action": ["iot:Subscribe"],
        "Resource": [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/microgrid/*/alerts"
        ]
      }
    ]
  })
}
