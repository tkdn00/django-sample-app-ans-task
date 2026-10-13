resource "aws_lb" "djangoapp_lb" {
  name               = "djangoapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

}

resource "aws_lb_target_group" "djangoapp_tg" {
  name                 = "djangoapp-ecs-tg"
  target_type          = "ip"
  vpc_id               = aws_vpc.django_app_vpc.id
  port                 = 8000
  protocol             = "HTTP"
  deregistration_delay = 30

  health_check {
    path                = "/api/v3/status/"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 15
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "djangoapp_listener" {
  load_balancer_arn = aws_lb.djangoapp_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.djangoapp_tg.arn
  }
}
