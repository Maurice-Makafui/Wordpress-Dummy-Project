variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the WordPress database"
  type        = string
}

variable "db_username" {
  description = "Master username for RDS (fetched from SSM)"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS (fetched from SSM)"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance type (e.g. db.t3.micro, db.t3.small)"
  type        = string
  default     = "db.t3.micro"
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB for RDS autoscaling. Set to 0 to disable."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS high availability. Recommended true for production."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated RDS backups (0 disables backups — not recommended)"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent the RDS instance from being deleted. Set false only to tear down."
  type        = bool
  default     = true
}

variable "iam_database_authentication_enabled" {
  description = "Allow IAM-based authentication to RDS in addition to password auth"
  type        = bool
  default     = false
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID to attach to the RDS instance"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
