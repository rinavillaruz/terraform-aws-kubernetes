# Load balancer
resource "aws_lb" "k8s_api" {
  name               = "k8s-api-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.private_subnets : subnet.id]
}

resource "aws_lb_target_group" "k8s_api" {
  name     = "k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol            = "TCP"
    port                = 6443
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}

# Master node attachment
resource "aws_lb_target_group_attachment" "k8s_api_master" {
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = aws_instance.control_plane["0"].id
  port             = 6443
}

# Secondary nodes attachment
resource "aws_lb_target_group_attachment" "k8s_api_secondary" {
  for_each         = aws_instance.control_plane_secondary
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = each.value.id
  port             = 6443
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             =  "forward"
    target_group_arn =  aws_lb_target_group.k8s_api.arn
  }
}