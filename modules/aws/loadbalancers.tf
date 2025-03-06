# Load balancer
resource "aws_lb" "k8s_api" {
  name               = "k8s-api-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.private_subnets : subnet.id]
}

resource "aws_lb" "app_lb" {
  name               = "k8s-app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.public_subnets_alb : subnet.id]
}