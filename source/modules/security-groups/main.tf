# ─── ALB SECURITY GROUP ──────────────────────────────────────────────────────
# Accepts HTTP (80) and HTTPS (443) from the internet.
# Egress is restricted to ECS tasks only — not open to the world.

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB: accepts HTTP/HTTPS from internet, forwards to ECS only"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Forward to ECS tasks on port 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-alb-sg" })
}

# ─── ECS SECURITY GROUP ──────────────────────────────────────────────────────
# Only accepts traffic from the ALB. Egress is scoped to RDS, EFS, and
# HTTPS (for SSM API calls and DockerHub image pulls via NAT Gateway).

resource "aws_security_group" "ecs" {
  name        = "${var.name_prefix}-ecs-sg"
  description = "ECS tasks: inbound from ALB only, outbound to RDS/EFS/HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description     = "MySQL to RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
  }

  egress {
    description     = "NFS to EFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.efs.id]
  }

  egress {
    description = "HTTPS outbound — SSM API calls and container image pulls via NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-ecs-sg" })
}

# ─── RDS SECURITY GROUP ──────────────────────────────────────────────────────
# Only accepts MySQL traffic from ECS tasks. No egress needed.

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS: inbound MySQL from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-rds-sg" })
}

# ─── EFS SECURITY GROUP ──────────────────────────────────────────────────────
# Only accepts NFS traffic from ECS tasks. No egress needed.

resource "aws_security_group" "efs" {
  name        = "${var.name_prefix}-efs-sg"
  description = "EFS: inbound NFS from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-efs-sg" })
}
