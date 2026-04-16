variable "name_prefix" {
  description = "Prefix for EFS resource names"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EFS mount targets (one per AZ)"
  type        = list(string)
}

variable "efs_sg_id" {
  description = "Security group ID to attach to EFS mount targets"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
