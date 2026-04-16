variable "name" {
  description = "Name for the ALB and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the target group in"
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB (must span at least 2 AZs)"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS termination"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Prevent the ALB from being deleted accidentally"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
