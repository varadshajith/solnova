output "telemetry_stream_name" {
  value = aws_kinesis_stream.telemetry.name
}

output "alerts_stream_name" {
  value = aws_kinesis_stream.alerts.name
}

output "iot_thing_type_name" {
  value = aws_iot_thing_type.device_type.name
}

output "iot_device_policy_name" {
  value = aws_iot_policy.device_policy.name
}

output "iot_topic_rules" {
  value = {
    telemetry = aws_iot_topic_rule.telemetry_to_kinesis.name
    alerts    = aws_iot_topic_rule.alerts_to_kinesis.name
  }
}
