resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Both username and password stored as SecureString (KMS-encrypted).
# ECS fetches these at task startup via the secrets field in the task definition.

resource "aws_ssm_parameter" "db_password" {
  name  = local.ssm_path_db_password
  type  = "SecureString"
  value = random_password.db_password.result
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "db_username" {
  name  = local.ssm_path_db_username
  type  = "SecureString"
  value = var.database_username
  tags  = local.common_tags
}
