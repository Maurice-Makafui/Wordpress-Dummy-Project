# ─── APPLICATION LOAD BALANCER ───────────────────────────────────────────────

resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  # Prevents accidental deletion of the ALB via Terraform or the console.
  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.common_tags, { Name = var.name })
}

# ─── TARGET GROUP ────────────────────────────────────────────────────────────
# Health check uses /wp-login.php — this works both before and after
# WordPress setup, unlike /wp-admin/install.php which redirects post-setup.

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/wp-login.php"
    protocol            = "HTTP"
    matcher             = "200,302"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
  }

  tags = merge(var.common_tags, { Name = "${var.name}-tg" })
}

# ─── HTTP LISTENER ───────────────────────────────────────────────────────────
# All HTTP traffic is permanently redirected to HTTPS (301).
# No unencrypted traffic ever reaches ECS.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ─── HTTPS LISTENER ──────────────────────────────────────────────────────────
# SSL terminates here. ACM certificate is attached.
# Traffic is forwarded to ECS tasks via the target group.

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
