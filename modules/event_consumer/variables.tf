variable "project" {
  type        = string
  description = "Project/name prefix"
}

variable "event_bus_name" {
  type        = string
  description = "Name of the EventBridge bus to attach the rule to"
}

variable "rule_name" {
  type        = string
  description = "Short name for the rule (will be prefixed with project)"
}

variable "event_pattern" {
  type        = string
  description = "JSON-encoded event pattern (use jsonencode(...) at call site)"
}

variable "target_arn" {
  type        = string
  description = "ARN of the target (Lambda/SQS/etc.)"
}

variable "target_id" {
  type        = string
  description = "Identifier for the target within the rule"
}

variable "dlq_arn" {
  type        = string
  description = "ARN of SQS queue for EventBridge DLQ"
}

variable "max_retries" {
  type        = number
  default     = 3
  description = "Maximum retry attempts for EventBridge delivery"
}

variable "max_event_age_secs" {
  type        = number
  default     = 300
  description = "Maximum event age (seconds) for EventBridge delivery"
}
