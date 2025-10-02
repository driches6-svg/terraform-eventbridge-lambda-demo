output "rule_arn" {
  description = "ARN of the EventBridge rule created by this module."
  value       = aws_cloudwatch_event_rule.this.arn
}

output "rule_name" {
  description = "Name of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.this.name
}

output "target_id" {
  description = "Target ID attached to the rule."
  value       = aws_cloudwatch_event_target.this.target_id
}
