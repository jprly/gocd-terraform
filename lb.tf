locals {
    availability_zones = toset(["us-east-2a", "us-east-2b", "us-east-2c"])
}


resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "az" {
  for_each = local.availability_zones
  availability_zone = each.key
}

resource "aws_lb_target_group" "gocd" {
  name     = "gocd-lb-tg-tf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb" "gocd" {
  name               = "gocd-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gocd-sg.id]
  subnets            = [for subnet in local.availability_zones : aws_default_subnet.az[subnet].id]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.gocd.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gocd.arn
  }
}

resource "aws_lb_target_group_attachment" "gocd" {
  target_group_arn = aws_lb_target_group.gocd.arn
  target_id        = aws_instance.gocd.id
  port             = 8153
}