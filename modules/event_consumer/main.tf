terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_cloudwatch_event_rule" "this" {
  name           = "${var.project}-${var.rule_name}"
  event_bus_name = var.event_bus_name
  event_pattern  = var.event_pattern
}

resource "aws_cloudwatch_event_target" "this" {
  rule           = aws_cloudwatch_event_rule.this.name
  event_bus_name = var.event_bus_name
  arn            = var.target_arn
  target_id      = var.target_id

  retry_policy {
    maximum_retry_attempts       = var.max_retries
    maximum_event_age_in_seconds = var.max_event_age_secs
  }

  dead_letter_config {
    arn = var.dlq_arn
  }
}
