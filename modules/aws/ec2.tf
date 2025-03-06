# Generate an RSA key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.root}/terraform-key-pair.pem"
}

# IAM
resource "aws_iam_user" "terraform_user" {
  name = "terraform-user"
}

resource "aws_iam_instance_profile" "kubernetes_master" {
  name = "kubernetes-master-profile"
  role = aws_iam_role.kubernetes_master.name
}

resource "aws_iam_role" "kubernetes_master" {
  name = "kubernetes-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kubernetes_worker" {
  name = "kubernetes-worker-profile"
  role = aws_iam_role.kubernetes_worker.name
}

resource "aws_iam_role" "kubernetes_worker" {
  name = "kubernetes-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Ec2
resource "aws_instance" "bastion" {
  count                   = length(var.public_subnet_cidrs)
  ami                     = "ami-064519b8c76274859"  # Replace with a Debian 12 AMI ID
  instance_type           = "t3.micro"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = aws_subnet.public_subnets[count.index].id  # This should work now

  tags = {
    Name = "${terraform.workspace} - Bastion Host"
  }
}

# Allocate an Elastic IP for each bastion host
resource "aws_eip" "bastion_eip" {
  count    = length(var.public_subnet_cidrs)
  domain   = "vpc"
}

# Associate each Elastic IP with a corresponding bastion instance
resource "aws_eip_association" "bastion_eip_assoc" {
  count         = length(var.public_subnet_cidrs)
  instance_id   = aws_instance.bastion[count.index].id
  allocation_id = aws_eip.bastion_eip[count.index].id
}

resource "aws_instance" "control_plane" {
  count                   = 3  # High availability with 3 control plane nodes
  ami                     = "ami-064519b8c76274859"  # Replace with a Debian 12 AMI ID
  instance_type           = "t3.medium"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.control_plane.id]
  subnet_id               = aws_subnet.private_subnets[count.index].id  # Fix: Access the ID properly
  iam_instance_profile    = aws_iam_instance_profile.kubernetes_master.name

  tags = {
    Name = "${terraform.workspace} - Control Plane Node ${count.index + 1}"
  }
}

resource "aws_instance" "worker_nodes" {
  count                   = 3  # Adjust based on workload needs
  ami                     = "ami-064519b8c76274859"  # Replace with a Debian 12 AMI ID
  instance_type           = "t3.large"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.worker_nodes.id]
  
  # Use modulo to distribute worker nodes across available subnets
  subnet_id               = aws_subnet.private_subnets[count.index % length(aws_subnet.private_subnets)].id

  iam_instance_profile    = aws_iam_instance_profile.kubernetes_worker.name

  tags = {
    Name = "${terraform.workspace} - Worker Node ${count.index + 1}"
  }
}

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