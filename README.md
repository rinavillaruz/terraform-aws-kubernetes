# Terraform AWS Kubernetes Cluster

This repository contains Terraform configurations to deploy a **production-ready Kubernetes cluster** on AWS. It leverages Terraform modules for infrastructure automation.

## 🛠️ Features
- **Security Groups** – Configurable Security groups for Bastion host, Control Plane and Worker Nodes
- **VPC & Networking** – Configurable VPC, subnets, NAT, IGW
- **KEY Pairs** – Create Key-Pairs
- **Control Plane and Worker Nodes** – PENDING
- **EC2 Instances** –  PENDING
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