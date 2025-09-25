data "aws_kinesis_stream" "telemetry" {
  name = var.telemetry_stream_name
}

data "aws_kinesis_stream" "alerts" {
  name = var.alerts_stream_name
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  lambda_name = "${local.name_prefix}-etl"
}

# DynamoDB alerts table (create if not provided)
resource "aws_dynamodb_table" "alerts" {
  count        = var.dynamodb_alerts_table_name == null ? 1 : 0
  name         = "${local.name_prefix}-alerts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alert_id"

  attribute {
    name = "alert_id"
    type = "S"
  }
}

locals {
  alerts_table_name = var.dynamodb_alerts_table_name != null ? var.dynamodb_alerts_table_name : aws_dynamodb_table.alerts[0].name
}

# Package Lambda code from repo
# Path to lambda source
locals {
  lambda_src = "${path.module}/../../../tools/lambda/etl"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.lambda_src
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-etl-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.name_prefix}-etl-logs"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${local.name_prefix}-etl-dynamodb"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["dynamodb:PutItem"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "etl" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.handler"
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      ALERTS_TABLE  = local.alerts_table_name
      INFLUX_URL    = ""
      INFLUX_ORG    = ""
      INFLUX_BUCKET = ""
      INFLUX_TOKEN  = ""
    }
  }
}

resource "aws_lambda_event_source_mapping" "telemetry" {
  event_source_arn  = data.aws_kinesis_stream.telemetry.arn
  function_name     = aws_lambda_function.etl.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}

resource "aws_lambda_event_source_mapping" "alerts" {
  event_source_arn  = data.aws_kinesis_stream.alerts.arn
  function_name     = aws_lambda_function.etl.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}
