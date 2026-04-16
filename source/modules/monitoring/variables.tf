variable "name_prefix" {
  description = "Prefix for all monitoring resource names"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications. Leave empty to skip."
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for alarm dimensions"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for alarm dimensions"
  type        = string
}

variable "rds_identifier" {
  description = "RDS instance identifier for alarm dimensions"
  type        = string
}

variable "rds_max_connections_threshold" {
  description = "Number of RDS connections that triggers the high-connections alarm"
  type        = number
  default     = 50
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for alarm dimensions (the part after 'app/')"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
