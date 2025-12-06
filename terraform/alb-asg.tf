#ALB (Application Load Balancer)
resource "aws_lb" "alb" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_sub1.id,
    aws_subnet.public_sub2.id
  ]
}

# Targate Group
resource "aws_lb_target_group" "TG" {
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/health"
    port = "traffic-port"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG.arn
  }
}

# Autoscalling group configuration
resource "aws_autoscaling_group" "ASG" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = [
    aws_subnet.private_sub1.id,
    aws_subnet.private_sub2.id
  ]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.TG.arn]
}
