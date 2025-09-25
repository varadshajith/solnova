variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS named profile (optional)"
  type        = string
  default     = null
}

variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "solnova"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "telemetry_stream_name" {
  description = "Kinesis stream name for telemetry"
  type        = string
}

variable "alerts_stream_name" {
  description = "Kinesis stream name for alerts"
  type        = string
}

variable "dynamodb_alerts_table_name" {
  description = "DynamoDB table name for alerts"
  type        = string
  default     = null
}
