output "event_bus_name" { value = aws_cloudwatch_event_bus.orders.name }
output "lambda_name" { value = aws_lambda_function.process_order.function_name }
output "rule_arn" { value = module.order_placed_consumer.rule_arn }
output "dlq_url" { value = aws_sqs_queue.event_dlq.url }
