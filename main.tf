terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 5.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Event bus (custom) ---
resource "aws_cloudwatch_event_bus" "orders" {
  name = var.event_bus_name
}

# --- DLQ (SQS) for EventBridge target ---
resource "aws_sqs_queue" "event_dlq" {
  name                      = "${var.project}-event-dlq"
  message_retention_seconds = 1209600 # 14 days
}

# --- Lambda IAM ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_basic" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "lambda_basic" {
  name   = "${var.project}-lambda-basic"
  policy = data.aws_iam_policy_document.lambda_basic.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic.arn
}

# Allow Lambda to send to the DLQ if you later use Lambda destinations
data "aws_iam_policy_document" "lambda_sqs" {
  statement {
    actions   = ["sqs:SendMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
    resources = [aws_sqs_queue.event_dlq.arn]
  }
}
resource "aws_iam_policy" "lambda_sqs" {
  name   = "${var.project}-lambda-sqs"
  policy = data.aws_iam_policy_document.lambda_sqs.json
}
resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs.arn
}

# --- Package Lambda from source ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# --- Lambda function ---
resource "aws_lambda_function" "process_order" {
  function_name = "${var.project}-process-order"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      POWERED_BY = "EventBridge"
    }
  }

  # Prevent stampede in small accounts
  reserved_concurrent_executions = 5
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.process_order.function_name}"
  retention_in_days = 14
}

# --- Reusable module to subscribe Lambda to an event pattern on our bus ---
module "order_placed_consumer" {
  source         = "./modules/event_consumer"
  project        = var.project
  event_bus_name = aws_cloudwatch_event_bus.orders.name

  rule_name = "order-placed"
  event_pattern = jsonencode({
    "source" : ["app.orders"],
    "detail-type" : ["orderPlaced"]
  })

  target_arn         = aws_lambda_function.process_order.arn
  target_id          = "sendToLambda"
  dlq_arn            = aws_sqs_queue.event_dlq.arn
  max_retries        = 5
  max_event_age_secs = 900
}

# Let EventBridge invoke the Lambda
resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_order.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.order_placed_consumer.rule_arn
}

# --- EventBridge Scheduler example (runs every 5 minutes) ---
resource "aws_scheduler_schedule" "heartbeat" {
  name        = "${var.project}-heartbeat"
  description = "Periodic heartbeat to Lambda"

  flexible_time_window { mode = "OFF" }
  schedule_expression = "rate(5 minutes)"

  target {
    arn      = aws_lambda_function.process_order.arn
    role_arn = aws_iam_role.scheduler_invoke.arn
    input    = jsonencode({ source = "scheduler.heartbeat", detail = { ping = true } })
  }
}

# IAM role for Scheduler to invoke Lambda
data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "scheduler_invoke" {
  name               = "${var.project}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
}
data "aws_iam_policy_document" "scheduler_invoke_lambda" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.process_order.arn]
  }
}
resource "aws_iam_policy" "scheduler_invoke_lambda" {
  name   = "${var.project}-scheduler-invoke"
  policy = data.aws_iam_policy_document.scheduler_invoke_lambda.json
}
resource "aws_iam_role_policy_attachment" "scheduler_invoke_attach" {
  role       = aws_iam_role.scheduler_invoke.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda.arn
}
