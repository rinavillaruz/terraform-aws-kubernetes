# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "bastion-sg" 
  vpc_id      = var.vpc_id
  description = "Security group for the bastion host"

  tags = {
    Name = "${terraform.workspace} - Bastion Host SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_anywhere" {
  security_group_id = aws_security_group.bastion.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow SSH access to bastion host from any IP address"

  tags = {
    Name = "${terraform.workspace} - Bastion SSH Internet Access"
  }
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_control_plane" {
  security_group_id             = aws_security_group.bastion.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.control_plane.id
  description = "Allow SSH from bastion host to Kubernetes control plane nodes for cluster administration"

  tags = {
    Name = "${terraform.workspace} - Bastion SSH to Control Plane"
  }
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_workers" {
  security_group_id             = aws_security_group.bastion.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.worker_node.id
  description                   = "Allow SSH from bastion host to worker nodes for maintenance and troubleshooting"
  
  tags = {
    Name = "${terraform.workspace} - Bastion SSH to Worker Nodes"
  }
}

# Control Plane
resource "aws_security_group" "control_plane" {
  name        = "control-plane-sg"  
  vpc_id      = var.vpc_id
  description = "Security group for the Kubernetes control plane"

  tags = {
    Name = "${terraform.workspace} - Kubernetes Control Plane SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_ssh" {
  security_group_id             = aws_security_group.control_plane.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.bastion.id
  description                   = "Allow SSH access to control plane nodes from bastion host for cluster administration"

  tags = {
    Name = "${terraform.workspace} - Control Plane SSH from Bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_etcd" {
  security_group_id = aws_security_group.control_plane.id
  from_port         = 2379
  to_port           = 2380
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow etcd client and peer communication within VPC for Kubernetes cluster state management"

  tags = {
    Name = "${terraform.workspace} - Control Plane etcd Communication"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_self_control_plane" {
  security_group_id = aws_security_group.control_plane.id
  from_port         = 10250
  to_port           = 10250
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow kubelet API access within VPC for control plane node communication and monitoring"

  tags = {
    Name = "${terraform.workspace} - Control Plane kubelet API"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_scheduler" {
  security_group_id             = aws_security_group.control_plane.id
  from_port                     = 10259
  to_port                       = 10259
  ip_protocol                   = "tcp"
  cidr_ipv4                     = var.vpc_cidr_block
  description                   = "Allow kube-scheduler metrics and health check access from VPC for cluster monitoring"

  tags = {
    Name = "${terraform.workspace} - Control Plane kube-scheduler"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_controller_manager" {
  security_group_id             = aws_security_group.control_plane.id
  from_port                     = 10257
  to_port                       = 10257
  ip_protocol                   = "tcp"
  cidr_ipv4                     = var.vpc_cidr_block
  description                   = "Allow kube-controller-manager metrics and health check access from VPC for cluster monitoring"
  
  tags = {
    Name = "${terraform.workspace} - Control Plane kube-controller-manager"
  }
}

resource "aws_vpc_security_group_egress_rule" "control_plane_egress_all" {
  security_group_id             = aws_security_group.control_plane.id
  
  // Only https bound
  // from_port                  =  443
  // to_port                    =  443 
  // ip_protocol                =  "tcp"

  ip_protocol                   = "-1"
  cidr_ipv4                     = "0.0.0.0/0"
  description                   = "Allow all outbound traffic from control plane for AWS APIs, container registries, and external services"

  tags = {
    Name = "${terraform.workspace} - Control Plane Outbound All"
  }
}

# Worker Node
resource "aws_security_group" "worker_node" {
  name        = "worker-node-sg"  
  vpc_id      = var.vpc_id
  description = "Security group for Kubernetes worker nodes - controls pod and application traffic"

  tags = {
    Name = "${terraform.workspace} - Worker Nodes SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "worker_node_egress_all" {
  security_group_id             = aws_security_group.worker_node.id
  ip_protocol                   = "-1"
  cidr_ipv4                     = "0.0.0.0/0"
  description                   = "Allow all outbound traffic from worker nodes for container images, application traffic, and AWS services"
  
  tags = {
    Name = "${terraform.workspace} - Worker Nodes Outbound All"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_ssh" {
  security_group_id             = aws_security_group.worker_node.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.bastion.id
  description                   = "Allow SSH access to worker nodes from bastion host for maintenance and troubleshooting"

  tags = {
    Name = "${terraform.workspace} - Worker Nodes SSH from Bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_kubelet_api" {
  security_group_id             =   aws_security_group.worker_node.id
  from_port                     =   10250
  to_port                       =   10250
  ip_protocol                   =   "tcp"
  referenced_security_group_id  =   aws_security_group.control_plane.id
  description = "Allow control plane access to worker node kubelet API for pod management and monitoring"
  tags = {
    Name = "${terraform.workspace} - Worker Nodes kubelet API"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_kube_proxy" {
  security_group_id             = aws_security_group.worker_node.id
  from_port                     = 10256
  to_port                       = 10256
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.elb.id
  description                   = "Allow load balancer access to kube-proxy health check endpoint on worker nodes"
  
  tags = {
    Name = "${terraform.workspace} - Worker Nodes kube-proxy"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_tcp_nodeport_services" {
  security_group_id   =   aws_security_group.worker_node.id
  from_port           =   30000
  to_port             =   32767
  ip_protocol         =   "tcp"
  cidr_ipv4           =   "0.0.0.0/0"
  description         = "Allow internet access to Kubernetes NodePort services (TCP 30000-32767) for application traffic"
  tags = {
    Name = "${terraform.workspace} - Worker Nodes NodePort TCP"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_udp_nodeport_services" {
  security_group_id   =   aws_security_group.worker_node.id
  from_port           =   30000
  to_port             =   32767
  ip_protocol         =   "udp"
  cidr_ipv4           =   "0.0.0.0/0"
  description         = "Allow internet access to Kubernetes NodePort services (UDP 30000-32767) for application traffic"
  tags = {
    Name = "${terraform.workspace} - Worker Nodes NodePort UDP"
  }
}

# NLB
resource "aws_vpc_security_group_ingress_rule" "allow_nlb_health_check" {
  security_group_id = aws_security_group.control_plane.id
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/16"
  description       = "Allow Network Load Balancer health checks to Kubernetes API server on port 6443"

  tags = {
    Name = "${terraform.workspace} - Control Plane NLB Health Check"
  }
}

# BGP
resource "aws_vpc_security_group_ingress_rule" "allow_bgp" {
  security_group_id   = aws_security_group.control_plane.id
  from_port           = 179
  to_port             = 179
  ip_protocol         = "tcp"
  cidr_ipv4           = var.vpc_cidr_block
  description         = "Allow BGP protocol communication within VPC for network routing and service mesh"

  tags = {
    Name = "${terraform.workspace} - Control Plane BGP Communication"
  }
}