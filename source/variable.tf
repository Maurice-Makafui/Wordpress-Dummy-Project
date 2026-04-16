variable "region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Deployment environment name (dev, staging, prod). Used in resource tags and names."
  type        = string
  default     = "dev"
}

# ─── NETWORKING ──────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — one per AZ. ALB lives here."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets — one per AZ. ECS, RDS, and EFS live here."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "azs" {
  description = "Availability zones to deploy into. Must match the number of subnet CIDRs."
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways. Use 1 for dev/staging to save cost. Use 2 (one per AZ) for production HA."
  type        = number
  default     = 1
}

# ─── DNS & SSL ───────────────────────────────────────────────────────────────

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS. Must be in the same region as your deployment."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for your domain."
  type        = string
}

variable "domain_name" {
  description = "Your registered domain name (e.g. example.com). A Route 53 A record will be created pointing to the ALB."
  type        = string
}

# ─── RDS ─────────────────────────────────────────────────────────────────────

variable "rds_identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
  default     = "cloudsec-rds"
}

variable "rds_db_name" {
  description = "Name of the WordPress database"
  type        = string
  default     = "wordpress_db"
}

variable "database_username" {
  description = "Master username for RDS. Avoid common defaults like 'admin' or 'root'."
  type        = string
  default     = "wpdbuser"
}

variable "instance_class" {
  description = "RDS instance type. Use db.t3.micro for dev, db.t3.small or larger for production."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ standby for RDS. Strongly recommended for production — provides automatic failover if the primary AZ goes down."
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Days to keep automated RDS backups. 0 disables backups entirely — not recommended."
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Prevent the RDS instance from being deleted. Set to false only when intentionally tearing down."
  type        = bool
  default     = true
}

variable "rds_max_allocated_storage" {
  description = "Maximum storage in GB for RDS autoscaling. RDS will expand automatically up to this limit."
  type        = number
  default     = 100
}

# ─── ECS ─────────────────────────────────────────────────────────────────────

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "Memory in MB for the ECS task"
  type        = number
  default     = 3072
}

variable "ecs_desired_count" {
  description = "Initial number of ECS tasks. Should match ecs_min_capacity."
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Minimum ECS tasks. Set to at least 2 so one task per AZ is always running."
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum ECS tasks auto scaling can scale out to"
  type        = number
  default     = 4
}

variable "wordpress_image" {
  description = "WordPress Docker image tag to deploy"
  type        = string
  default     = "wordpress:php8.3-apache"
}

# ─── ALB ─────────────────────────────────────────────────────────────────────

variable "alb_name" {
  description = "Name for the Application Load Balancer"
  type        = string
  default     = "cloudsec-alb"
}

variable "alb_deletion_protection" {
  description = "Prevent the ALB from being deleted accidentally"
  type        = bool
  default     = true
}

# ─── MONITORING ──────────────────────────────────────────────────────────────

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications via SNS. Leave empty to skip email subscription."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}
