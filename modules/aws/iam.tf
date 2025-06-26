# IAM
resource "aws_iam_user" "terraform_user" {
  name = "terraform-user"
}

resource "aws_iam_instance_profile" "kubernetes_master" {
  name = "kubernetes-master-profile"
  role = aws_iam_role.kubernetes_master.name
}

data "aws_caller_identity" "current" {}

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

# Add SSM permissions to master role
resource "aws_iam_role_policy" "kubernetes_master_ssm" {
  name = "kubernetes-master-ssm-policy"
  role = aws_iam_role.kubernetes_master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:DeleteParameter",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/k8s/*"
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

resource "aws_iam_role_policy" "kubernetes_worker_ssm" {
  name = "kubernetes-worker-ssm-policy"
  role = aws_iam_role.kubernetes_worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/k8s/*"
      }
    ]
  })
}