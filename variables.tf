variable "project" {
  type        = string
  description = "Project/name prefix for resources"
  default     = "eventbridge-demo"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider"
  default     = "eu-west-2" # London
}

variable "event_bus_name" {
  type        = string
  description = "Custom EventBridge bus name"
  default     = "orders-bus"
}
