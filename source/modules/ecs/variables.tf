variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "region" {
  description = "AWS region for CloudWatch logs"
  type        = string
}

variable "wordpress_image" {
  description = "Docker image for WordPress (e.g. wordpress:php8.3-apache)"
  type        = string
  default     = "wordpress:php8.3-apache"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory in MB for the ECS task"
  type        = number
  default     = 3072
}

variable "desired_count" {
  description = "Initial number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks (set >= 2 for HA across AZs)"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto scaling"
  type        = number
  default     = 4
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks (tasks are NOT publicly accessible)"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group to register tasks with"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint passed as WORDPRESS_DB_HOST environment variable"
  type        = string
}

variable "db_name" {
  description = "Database name passed as WORDPRESS_DB_NAME environment variable"
  type        = string
}

variable "ssm_db_username_arn" {
  description = "ARN of the SSM parameter holding the DB username"
  type        = string
}

variable "ssm_db_password_arn" {
  description = "ARN of the SSM parameter holding the DB password"
  type        = string
}

variable "ssm_parameter_arns" {
  description = "List of SSM parameter ARNs the execution role is allowed to read"
  type        = list(string)
}

variable "efs_file_system_id" {
  description = "ID of the EFS file system to mount"
  type        = string
}

variable "efs_file_system_arn" {
  description = "ARN of the EFS file system (used for scoped IAM policy)"
  type        = string
}

variable "efs_access_point_id" {
  description = "ID of the EFS access point"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
