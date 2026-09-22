resource "aws_lb" "djangoapp_lb" {
  name               = "lb-djangoapp"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

}

resource "aws_lb_target_group" "djangoapp-tg" {
  name        = "djangoapp-tg"
  target_type = "instance"
  vpc_id      = aws_vpc.django_app_vpc.id
  port        = 80
  protocol    = "HTTP"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = 80
    timeout             = 15
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "instance1" {
  target_group_arn = aws_lb_target_group.djangoapp-tg.arn
  target_id        = aws_instance.app_instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance2" {
  target_group_arn = aws_lb_target_group.djangoapp-tg.arn
  target_id        = aws_instance.app_instance2.id
  port             = 80
}

resource "aws_lb_listener" "djangoapp_listener" {
  load_balancer_arn = aws_lb.djangoapp_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.djangoapp-tg.arn
  }
}