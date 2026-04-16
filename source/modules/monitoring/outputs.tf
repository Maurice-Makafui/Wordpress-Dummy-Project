output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic — subscribe your email or webhook here"
  value       = aws_sns_topic.alerts.arn
}
