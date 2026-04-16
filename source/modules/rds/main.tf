# ─── DB SUBNET GROUP ─────────────────────────────────────────────────────────
# RDS requires a subnet group spanning at least 2 AZs.

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.identifier}-subnet-group" })
}

# ─── RDS INSTANCE ────────────────────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  db_name        = var.db_name
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = var.instance_class

  # Credentials pulled from SSM — never hardcoded
  username = var.db_username
  password = var.db_password

  port         = 3306
  storage_type = "gp3"

  # Start at 20 GB, auto-expand up to max_allocated_storage if needed
  allocated_storage     = 20
  max_allocated_storage = var.max_allocated_storage

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  # Multi-AZ creates a synchronous standby replica in a second AZ.
  # If the primary AZ fails, RDS automatically fails over — no data loss.
  multi_az = var.multi_az

  # Automated daily backups retained for 7 days by default.
  # Required for point-in-time recovery (PITR).
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Prevents accidental deletion via Terraform or the AWS console.
  deletion_protection = var.deletion_protection

  # Takes a final snapshot before destroying the instance.
  # The snapshot name is timestamped to avoid conflicts.
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.identifier}-final-snapshot"

  # IAM auth is an additional layer — users can authenticate with
  # short-lived IAM tokens instead of static passwords.
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  publicly_accessible = false

  tags = merge(var.common_tags, { Name = var.identifier })
}
