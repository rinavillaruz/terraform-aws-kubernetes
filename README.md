# Terraform AWS Kubernetes Cluster

This repository contains Terraform configurations to deploy a **production-ready Kubernetes cluster** on AWS. It leverages Terraform modules for infrastructure automation.

## 🛠️ Features
- **Security Groups** – Configurable Security groups for Bastion host, Control Plane and Worker Nodes
- **VPC & Networking** – Configurable VPC, subnets, NAT, IGW
- **KEY Pairs**
- **Control Plane and Worker Nodes**
- **EC2 Instances**
- **IAM Roles**
- **Network Load Balancer and Application Load Balancer**
- **Terraform Modules** – Modular and reusable code structure using Workspaces

## 📌 Prerequisites
- Terraform (`v1.10.5`)
- AWS CLI (`v2.15.15`)
- An AWS account with sufficient permissions

## 🚀 Deployment Steps
1. Clone this repo:
   ```sh
   git clone https://github.com/rinavillaruz/terraform-aws-kubernetes.git
   cd terraform-aws-kubernetes
2. Provision Jenkins, AWS and Terraform locally https://gist.github.com/rinavillaruz/66c5de53833aa0e3a357cc9650e96724
3. Create a workspace
   ```sh
   terraform workspace new development