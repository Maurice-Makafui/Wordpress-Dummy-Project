locals {
  name_prefix = "cloudsec"

  ssm_path_db_password = "/${local.name_prefix}/${var.region}/rds/password"
  ssm_path_db_username = "/${local.name_prefix}/${var.region}/rds/username"

  common_tags = {
    Project     = "CloudSec"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
