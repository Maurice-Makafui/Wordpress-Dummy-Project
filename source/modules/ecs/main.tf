# ─── CLOUDWATCH LOG GROUP ────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_days
  tags              = var.common_tags
}

# ─── IAM — EXECUTION ROLE ────────────────────────────────────────────────────
# Used by the ECS agent to pull the container image and fetch secrets from SSM.
# Scoped to only the specific SSM parameters this service needs.

resource "aws_iam_role" "execution" {
  name = "${var.cluster_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "execution_base" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Scoped SSM policy — only allows reading the specific parameters this
# service needs. Replaces the broad AmazonSSMReadOnlyAccess managed policy.
resource "aws_iam_role_policy" "execution_ssm" {
  name = "${var.cluster_name}-ssm-read"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "ssm:GetParameter"]
      Resource = var.ssm_parameter_arns
    }]
  })
}

# ─── IAM — TASK ROLE ─────────────────────────────────────────────────────────
# Used by the running WordPress container itself.
# Scoped to only the specific EFS file system this task mounts.

resource "aws_iam_role" "task" {
  name = "${var.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "task_efs" {
  name = "${var.cluster_name}-efs-access"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      Resource = var.efs_file_system_arn
    }]
  })
}

# ─── ECS CLUSTER ─────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = var.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # Default strategy: prefer FARGATE_SPOT for cost savings.
  # ECS will fall back to FARGATE if Spot capacity is unavailable.
  # For production, swap weights (FARGATE weight=1, SPOT weight=0) or
  # set base=1 on FARGATE to guarantee at least one on-demand task.
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 1
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 3
  }
}

# ─── ECS TASK DEFINITION ─────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.cluster_name}-task"
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = var.wordpress_image
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true

      portMappings = [{ containerPort = 80, hostPort = 80 }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.region
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Non-sensitive config passed as plain environment variables
      environment = [
        { name = "WORDPRESS_DB_HOST", value = var.rds_endpoint },
        { name = "WORDPRESS_DB_NAME", value = var.db_name }
      ]

      # Sensitive values fetched from SSM at task startup — never in plaintext
      secrets = [
        { name = "WORDPRESS_DB_USER",     valueFrom = var.ssm_db_username_arn },
        { name = "WORDPRESS_DB_PASSWORD", valueFrom = var.ssm_db_password_arn }
      ]

      mountPoints = [{
        sourceVolume  = "efs-wordpress"
        containerPath = "/var/www/html"
        readOnly      = false
      }]
    }
  ])

  volume {
    name = "efs-wordpress"

    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049

      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  tags = var.common_tags
}

# ─── ECS SERVICE ─────────────────────────────────────────────────────────────
# Tasks run in PRIVATE subnets — not directly reachable from the internet.
# The ALB forwards traffic to them via the target group.
# assign_public_ip = false because tasks reach the internet via NAT Gateway.

resource "aws_ecs_service" "this" {
  name                              = "${var.cluster_name}-service"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "wordpress"
    container_port   = 80
  }

  # Ensure the cluster capacity providers are configured before the service
  depends_on = [aws_ecs_cluster_capacity_providers.this]

  tags = var.common_tags
}

# ─── AUTO SCALING ────────────────────────────────────────────────────────────
# min_capacity = 2 ensures at least one task per AZ at all times.
# If one AZ goes down, the other task keeps the service alive.

resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.cluster_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.cluster_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
