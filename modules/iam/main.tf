# IAM
data "aws_caller_identity" "current" {}

resource "random_id" "cluster" {
  byte_length = 4
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

  tags = {
    Name        = "${terraform.workspace} - Kubernetes Master Role"
    Description = "IAM role for Kubernetes control plane nodes with AWS API permissions"
    Purpose     = "Kubernetes Control Plane"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    Project     = "Kubernetes"
    NodeType    = "Control Plane"
    Service     = "EC2"
  }
}

resource "aws_iam_instance_profile" "kubernetes_master" {
  name = "kubernetes-master-profile-${random_id.cluster.hex}" 
  role = aws_iam_role.kubernetes_master.name

  tags = {
    Name        = "${terraform.workspace} - Kubernetes Control Plane Instance Profile"
    Description = "Instance profile for control plane nodes - enables AWS API access for cluster management"
    Purpose     = "Kubernetes Control Plane"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

# SSM parameter access policy for Kubernetes control plane - allows storing/retrieving cluster join tokens
resource "aws_iam_role_policy" "kubernetes_master_ssm" {
  name = "kubernetes-master-ssm-policy"
  role = aws_iam_role.kubernetes_master.id
  
  policy = jsonencode({
    # Policy grants control plane full access to SSM parameters under /k8s/ namespace
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",     # Store cluster join command with tokens and CA cert hash
          "ssm:GetParameter",     # Retrieve existing parameters for validation
          "ssm:DeleteParameter",  # Clean up expired or invalid join tokens
          "ssm:DescribeParameters" # List and discover available k8s parameters
        ]
        # Restrict access to only k8s namespace parameters for security
        Resource = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/k8s/*"
      }
    ]
  })
}

resource "aws_iam_role" "kubernetes_worker" {
  name = "kubernetes-worker-profile-${random_id.cluster.hex}"

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

  tags = {
    Name        = "${terraform.workspace} - Kubernetes Worker Role"
    Description = "IAM role for Kubernetes worker nodes with permissions for pod networking, storage, and container operations"
    Purpose     = "Kubernetes Worker Nodes"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_instance_profile" "kubernetes_worker" {
  name = "kubernetes-worker-profile"
  role = aws_iam_role.kubernetes_worker.name

  tags = {
    Name        = "${terraform.workspace} - Kubernetes Worker Instance Profile"
    Description = "Instance profile for worker nodes - enables AWS API access for container operations and networking"
    Purpose     = "Kubernetes Worker Nodes"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

# Worker node SSM access - read-only permissions to get cluster join command
resource "aws_iam_role_policy" "kubernetes_worker_ssm" {
  name = "kubernetes-worker-ssm-policy"
  role = aws_iam_role.kubernetes_worker.id
  
  policy = jsonencode({
    # Policy allows worker nodes to read SSM parameters under /k8s/ path
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",   # Read join command stored by control plane
          "ssm:GetParameters"   # Batch read multiple parameters if needed
        ]
        # Only allow access to k8s namespace parameters
        Resource = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/k8s/*"
      }
    ]
  })
}