variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all security group names"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
