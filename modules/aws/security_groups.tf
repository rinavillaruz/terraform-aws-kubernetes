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
    Name = "${terraform.workspace} - SSH Incoming - Bastion SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_anywhere" {
  security_group_id = aws_security_group.bastion.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${terraform.workspace} - SSH Incoming Anywhere - Bastion SG"
  }
}

# Bastion Host Egress Rule (Allow SSH to Control Plane & Worker Nodes)
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

# resource "aws_vpc_security_group_egress_rule" "bastion_egress_workers" {
#   security_group_id = aws_security_group.bastion.id
#   from_port         = 22
#   to_port           = 22
#   ip_protocol         = "tcp"
#   referenced_security_group_id = aws_security_group.bastion.id

#   tags = {
#     Name = "${terraform.workspace} - SSH Outgoing - Bastion / Worker Nodes SG"
#   }
# }

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
  security_group_id = aws_security_group.control_plane.id
  from_port         = 22
  to_port           = 22
  ip_protocol         = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name = "${terraform.workspace} - SSH Incoming - Control Plane SG / Bastion SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_api" {
  security_group_id = aws_security_group.control_plane.id
  from_port         = 6443
  to_port           = 6443
  ip_protocol         = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${terraform.workspace} - TCP Incoming - Control Plane SG - Kubernetes API Server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_etcd" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   2379
  to_port                       =   2380
  ip_protocol                   =   "tcp"
  cidr_ipv4                   = aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - TCP Incoming - Control Plane SG - etcd Server Client API"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_self_control_plane" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   10250
  to_port                       =   10250
  ip_protocol                   =   "tcp"
  cidr_ipv4                   = aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - TCP Incoming - Control Plane SG - self, Control Plane"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_scheduler" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   10259
  to_port                       =   10259
  ip_protocol                   =   "tcp"
  cidr_ipv4                   = aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - TCP Incoming - Control Plane SG - kube scheduler"
  }
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_kube_controller_manager" {
  security_group_id             =   aws_security_group.control_plane.id
  from_port                     =   10257
  to_port                       =   10257
  ip_protocol                   =   "tcp"
  cidr_ipv4                     = aws_vpc.main.cidr_block
  tags = {
    Name = "${terraform.workspace} - TCP Incoming - Control Plane SG - kube controller manager"
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

resource "aws_vpc_security_group_ingress_rule" "allow_internal_all" {
  security_group_id = aws_security_group.control_plane.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.main.cidr_block
}

// TODO:: Worker Nodes Security Group