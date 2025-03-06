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