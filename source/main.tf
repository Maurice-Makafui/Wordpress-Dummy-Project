# ─── NETWORKING ──────────────────────────────────────────────────────────────
# VPC, public/private subnets, IGW, NAT Gateway(s), route tables, VPC Flow Logs

module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  vpc_name             = "${local.name_prefix}-vpc"
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  nat_gateway_count    = var.nat_gateway_count
  log_retention_days   = var.log_retention_days
  common_tags          = local.common_tags
}

# ─── SECURITY GROUPS ─────────────────────────────────────────────────────────
# ALB, ECS, RDS, and EFS security groups with least-privilege rules

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id      = module.networking.vpc_id
  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

# ─── EFS ─────────────────────────────────────────────────────────────────────
# Encrypted shared file system for WordPress wp-content, with backup enabled

module "efs" {
  source = "./modules/efs"

  name_prefix        = local.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  efs_sg_id          = module.security_groups.efs_sg_id
  common_tags        = local.common_tags
}

# ─── RDS ─────────────────────────────────────────────────────────────────────
# MySQL 8.0 in private subnets with Multi-AZ, backups, and deletion protection

module "rds" {
  source = "./modules/rds"

  identifier              = var.rds_identifier
  db_name                 = var.rds_db_name
  db_username             = aws_ssm_parameter.db_username.value
  db_password             = aws_ssm_parameter.db_password.value
  instance_class          = var.instance_class
  max_allocated_storage   = var.rds_max_allocated_storage
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  private_subnet_ids      = module.networking.private_subnet_ids
  rds_sg_id               = module.security_groups.rds_sg_id
  common_tags             = local.common_tags
}

# ─── ALB ─────────────────────────────────────────────────────────────────────
# Internet-facing ALB in public subnets — the only public entry point

module "alb" {
  source = "./modules/alb"

  name                       = var.alb_name
  vpc_id                     = module.networking.vpc_id
  alb_sg_id                  = module.security_groups.alb_sg_id
  public_subnet_ids          = module.networking.public_subnet_ids
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = var.alb_deletion_protection
  common_tags                = local.common_tags
}

# ─── ECS ─────────────────────────────────────────────────────────────────────
# Fargate tasks in PRIVATE subnets — not directly internet-accessible

module "ecs" {
  source = "./modules/ecs"

  cluster_name        = "${local.name_prefix}-cluster"
  region              = var.region
  wordpress_image     = var.wordpress_image
  task_cpu            = var.ecs_task_cpu
  task_memory         = var.ecs_task_memory
  desired_count       = var.ecs_desired_count
  min_capacity        = var.ecs_min_capacity
  max_capacity        = var.ecs_max_capacity
  log_retention_days  = var.log_retention_days
  private_subnet_ids  = module.networking.private_subnet_ids
  ecs_sg_id           = module.security_groups.ecs_sg_id
  target_group_arn    = module.alb.target_group_arn
  rds_endpoint        = module.rds.endpoint
  db_name             = var.rds_db_name
  ssm_db_username_arn = aws_ssm_parameter.db_username.arn
  ssm_db_password_arn = aws_ssm_parameter.db_password.arn
  ssm_parameter_arns  = [aws_ssm_parameter.db_username.arn, aws_ssm_parameter.db_password.arn]
  efs_file_system_id  = module.efs.file_system_id
  efs_file_system_arn = "arn:aws:elasticfilesystem:${var.region}:${data.aws_caller_identity.current.account_id}:file-system/${module.efs.file_system_id}"
  efs_access_point_id = module.efs.access_point_id
  common_tags         = local.common_tags
}

# ─── MONITORING ──────────────────────────────────────────────────────────────
# SNS topic + CloudWatch alarms for ECS, RDS, and ALB

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix                   = local.name_prefix
  alert_email                   = var.alert_email
  ecs_cluster_name              = module.ecs.cluster_name
  ecs_service_name              = module.ecs.service_name
  rds_identifier                = module.rds.identifier
  rds_max_connections_threshold = 50
  alb_arn_suffix                = module.alb.arn
  common_tags                   = local.common_tags
}

# ─── ROUTE 53 ────────────────────────────────────────────────────────────────
# Alias A record pointing your domain to the ALB

resource "aws_route53_record" "wordpress" {
  zone_id         = var.hosted_zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

# ─── DATA SOURCES ────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
