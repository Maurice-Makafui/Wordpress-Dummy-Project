output "wordpress_url" {
  description = "WordPress site URL"
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name — use this to test before DNS propagates"
  value       = module.alb.dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.rds.endpoint
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "ssm_db_password_path" {
  description = "SSM Parameter Store path for the DB password"
  value       = aws_ssm_parameter.db_password.name
}

output "ssm_db_username_path" {
  description = "SSM Parameter Store path for the DB username"
  value       = aws_ssm_parameter.db_username.name
}

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications — subscribe your email or webhook here"
  value       = module.monitoring.sns_topic_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}
