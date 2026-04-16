# ─── EFS FILE SYSTEM ─────────────────────────────────────────────────────────
# Encrypted at rest. Shared across all ECS tasks for WordPress wp-content.

resource "aws_efs_file_system" "this" {
  encrypted = true
  tags      = merge(var.common_tags, { Name = "${var.name_prefix}-efs" })
}

# ─── EFS BACKUP POLICY ───────────────────────────────────────────────────────
# Enables AWS Backup for EFS. Creates daily backups retained per your
# backup plan. Without this, EFS data is not backed up automatically.

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}

# ─── MOUNT TARGETS ───────────────────────────────────────────────────────────
# One mount target per private subnet (one per AZ).
# ECS tasks in any AZ can mount the same EFS file system.

resource "aws_efs_mount_target" "this" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

# ─── ACCESS POINT ────────────────────────────────────────────────────────────
# Scopes ECS access to a specific directory within EFS.
# Combined with IAM enforcement, this prevents tasks from accessing
# other directories on the same file system.

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
  tags           = merge(var.common_tags, { Name = "${var.name_prefix}-efs-ap" })
}
