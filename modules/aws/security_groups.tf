# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for the bastion host"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${terraform.workspace} - Bastion SG"
  }
}

# Bastion Host Ingress Rule (SSH from specific IP)
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.main.cidr_block

  tags = {
    Name = "${terraform.workspace} - Bastion SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_anywhere" {
  security_group_id = aws_security_group.bastion.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${terraform.workspace} - Bastion SG"
  }
}

# Bastion Host Egress Rule (Allow SSH to Control Plane)
resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id             = aws_security_group.bastion.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.control_plane.id

  tags = {
    Name = "${terraform.workspace} - SSH Outgoing - Bastion SG / Control Plane SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_workers" {
  security_group_id             = aws_security_group.bastion.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.worker_node.id

  tags = {
    Name = "${terraform.workspace} - SSH Outgoing - Bastion / Worker Nodes SG"
  }
}

// CONTROL PLANE
# Control Plane Security Group
resource "aws_security_group" "control_plane" {
  name        = "control-plane-sg"
  description = "Security group for the Kubernetes control plane"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace} - Control Plane SG"
  }
}

# Control Plane Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "control_plane_ssh" {
  security_group_id             = aws_security_group.control_plane.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.bastion.id

  tags = {
    Name = "${terraform.workspace} - Control Plane SG / Bastion SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_etcd" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   2379
  to_port                       =   2380
  ip_protocol                   =   "tcp"
  cidr_ipv4                     =   aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - Control Plane SG - etcd Server Client API"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_self_control_plane" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   10250
  to_port                       =   10250
  ip_protocol                   =   "tcp"
  cidr_ipv4                     =   aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - Control Plane SG - self, Control Plane"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_scheduler" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   10259
  to_port                       =   10259
  ip_protocol                   =   "tcp"
  cidr_ipv4                   = aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - Control Plane SG - kube scheduler"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_controller_manager" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   10257
  to_port                       =   10257
  ip_protocol                   =   "tcp"
  cidr_ipv4                     = aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - Control Plane SG - kube controller manager"
  }
}

resource "aws_vpc_security_group_egress_rule" "control_plane_egress_all" {
  security_group_id =   aws_security_group.control_plane.id
  ip_protocol       =   "-1"
  cidr_ipv4         =   "0.0.0.0/0"
  tags = {
    Name = "${terraform.workspace} - Outgoing - Control Plane SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "worker_node_egress_all" {
  security_group_id =   aws_security_group.worker_node.id
  ip_protocol       =   "-1"
  cidr_ipv4         =   "0.0.0.0/0"
  tags = {
    Name = "${terraform.workspace} - Outgoing - Worker Node SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_nlb_health_check" {
  security_group_id = aws_security_group.control_plane.id
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/16"

  tags = {
    Name = "${terraform.workspace} - Control Plane SG - Allow NLB health check"
  }
}

resource "aws_security_group" "elb" {
  name        = "k8s-elb-sg"
  description = "Security group for Kubernetes API load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "k8s-elb"
  }
}

// WORKER NODES
# Worker Node Security Group
resource "aws_security_group" "worker_node" {
  name        = "worker-node-sg"
  description = "Security group for the Kubernetes worker node"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace} - Worker Node SG"
  }
}

# Control Plane Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "worker_node_ssh" {
  security_group_id             = aws_security_group.worker_node.id
  from_port                     = 22
  to_port                       = 22
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.bastion.id

  tags = {
    Name = "${terraform.workspace} - Worker Node SG / Bastion SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_kubelet_api" {
  security_group_id             =   aws_security_group.worker_node.id
  from_port                     =   10250
  to_port                       =   10250
  ip_protocol                   =   "tcp"
  referenced_security_group_id  =   aws_security_group.control_plane.id
  tags = {
    Name = "${terraform.workspace} - Worker Node SG - Kubelet API"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_kube_proxy" {
  security_group_id             =   aws_security_group.worker_node.id
  from_port                     =   10256
  to_port                       =   10256
  ip_protocol                   =   "tcp"
  referenced_security_group_id  =   aws_security_group.elb.id
  tags = {
    Name = "${terraform.workspace} - Worker Node SG - Kube Proxy"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_tcp_nodeport_services" {
  security_group_id   =   aws_security_group.worker_node.id
  from_port           =   30000
  to_port             =   32767
  ip_protocol         =   "tcp"
  cidr_ipv4           =   "0.0.0.0/0"
  tags = {
    Name = "${terraform.workspace} - Worker Node SG - NodePort Services TCP"
  }
}

resource "aws_vpc_security_group_ingress_rule" "worker_node_udp_nodeport_services" {
  security_group_id   =   aws_security_group.worker_node.id
  from_port           =   30000
  to_port             =   32767
  ip_protocol         =   "udp"
  cidr_ipv4           =   "0.0.0.0/0"
  tags = {
    Name = "${terraform.workspace} - Worker Node SG - NodePort Services UDP"
  }
}

#########
# ELB Security Group Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "elb_api_server" {
  security_group_id = aws_security_group.elb.id
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"  # Or restrict to specific CIDR blocks as needed

  tags = {
    Name = "${terraform.workspace} - ELB SG - Kubernetes API Server"
  }
}

# ELB Security Group Egress Rules
resource "aws_vpc_security_group_egress_rule" "elb_to_control_plane" {
  security_group_id            = aws_security_group.elb.id
  from_port                    = 6443
  to_port                      = 6443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name = "${terraform.workspace} - ELB SG to Control Plane SG"
  }
}

# Update Control Plane Security Group to allow traffic from ELB
resource "aws_vpc_security_group_ingress_rule" "control_plane_api_from_elb" {
  security_group_id             = aws_security_group.control_plane.id
  from_port                     = 6443
  to_port                       = 6443
  ip_protocol                   = "tcp"
  referenced_security_group_id  = aws_security_group.elb.id

  tags = {
    Name = "${terraform.workspace} - Control Plane SG - API Server from ELB"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_bgp" {
  security_group_id   = aws_security_group.control_plane.id
  from_port           = 179
  to_port             = 179
  ip_protocol         = "tcp"
  cidr_ipv4           = aws_vpc.main.cidr_block

  tags = {
    Name = "${terraform.workspace} - Control Plane SG - Allow BGP"
  }
}