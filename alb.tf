resource "aws_security_group" "alb" {
  name        = "${var.name}-frontend"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-frontend"
  }
}

resource "aws_security_group_rule" "frontend_ingress_https" {
  cidr_blocks       = var.allowed_access_cidr_blocks
  description       = "Allow external communication with the ALB"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "frontend_ingress_http" {
  cidr_blocks       = var.allowed_access_cidr_blocks
  description       = "Allow external communication with the ALB"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 80
  type              = "ingress"
}

resource "aws_lb" "this" {
  name               = "${var.name}-frontend"
  subnets            = aws_subnet.public[*].id
  load_balancer_type = "application"

  enable_cross_zone_load_balancing = true
  idle_timeout                     = 3600

  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "${var.name}-frontend"
  }
}

resource "aws_lb_listener" "this_80" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "this_443" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "this" {
  name                 = "${var.name}-frontend"
  deregistration_delay = 300
  vpc_id               = aws_vpc.this.id
  protocol             = "HTTP"
  port                 = 80

  health_check {
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    matcher             = "200"
    path                = "/healthz"
  }

  tags = {
    Name = "${var.name}-frontend"
  }

  lifecycle {
    create_before_destroy = true
  }
}
