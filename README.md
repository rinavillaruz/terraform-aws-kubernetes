# Terraform AWS Multi-Cluster Kubernetes

This repository contains Terraform configurations to deploy a **Production-Ready Multi-Cluster Kubernetes** on AWS. It leverages Terraform modules for infrastructure automation.

## 🛠️ Features
- **Security Groups** – Configurable Security groups for Bastion host, Control Plane and Worker Nodes
- **VPC & Networking** – Configurable VPC, subnets, NAT, IGW
- **KEY Pairs**
- **Control Plane and Worker Nodes**
- **EC2 Instances**
- **IAM Roles**
- **Network Load Balancer**
- **Terraform Modules** – Modular and reusable code structure using Workspaces
- **AWS Parameter Store** - to store join commands

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
3. Create a workspace.
   ```sh
   terraform workspace new development

## 📝 SSH to the Bastion host using Agent Forwarding
   ```sh
      eval "$(ssh-agent -s)"
      ssh-add your-key.pem
      # ssh into bastion (use admin for debian) this is the key.pem
      # generated by terraform inside environments/development or
      # environments/production
      ssh -i your-key.pem -A admin@[bastion-public-ip]
      # when you are inside bastion host, ssh into control planes and
      # worker nodes (use admin for debian)
      ssh admin@[private-instance-ip]
   ```
or you can execute environments/development/bastion-access.sh

## AWS IAM User **terraform-user**
- **AmazonEC2FullAccess** (attach this to the terraform-user User in IAM)

## Policies
- **Terraform-User-Attached** (attach this to the terraform-user User in IAM)
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:GetInstanceProfile",
                "iam:GetPolicy",
                "iam:ListAttachedUserPolicies",
                "iam:GetUser",
                "iam:CreatePolicy",
                "iam:AttachUserPolicy",
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:PassRole",
                "iam:ListInstanceProfiles",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:UpdateAssumeRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "ssm:PutParameter",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:DeleteParameter",
                "ssm:DescribeParameters",
                "ssm:ListTagsForResource",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:ListGroupsForUser",
                "iam:RemoveUserFromGroup",
                "iam:DeleteInstanceProfile",
                "iam:DeleteRole",
                "iam:DetachRolePolicy",
                "iam:DetachUserPolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:DeleteUser"
            ],
            "Resource": [
                "arn:aws:iam::847153342117:policy/Terraform-User-Attached",
                "arn:aws:iam::847153342117:role/kubernetes-*",
                "arn:aws:iam::847153342117:instance-profile/kubernetes-*",
                "arn:aws:iam::847153342117:user/terraform*",
                "arn:aws:ssm:us-east-1:847153342117:parameter/k8s/*"
            ]
        },
        {
            "Sid": "SSMDescribeAccess",
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
}
```

## 📝 Changelog
**July 8, 2025**
- Refactor Terraform scripts into reusable modules

**July 8, 2025**
- Refactor Terraform scripts into reusable modules
**July 3, 2025**
- Shared logging and error handling across all nodes.
- Enhanced control plane initialization. It waits for Control Plane 1 to be ready before creating Control Planes 2 and 3 for smooth joining. 
- Worker node readiness check. Ensures all worker nodes join the cluster.
- Automated worker node labeling. Converts "none" role to "worker"
- Added comprehensive logging and it is being stored in /tmp/terraform-*-debug.log

**June 28, 2025**
- Associated an Elastic IP (EIP) to the bastion host instances.
- Implemented aws_eip and aws_eip_association resources in Terraform.
- Implemented AWS SSM Parameter Store to store join commands
- Added .sh.tmpl template to automate control plane and worker node setup through EC2 user_data


## To verify if the endpoint has changed,
```sh
kubectl cluster-info
```

You will see something like
```sh
Kubernetes control plane is running at https://xxx.elb.us-east-1.amazonaws.com:6443
CoreDNS is running at https://xxx.elb.us-east-1.amazonaws.com:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

To test if DNS is working (should test inside the VPC else it won't work)
```sh
curl -k https://xxx.elb.us-east-1.amazonaws.com:6443/version
```
or
```sh
time curl -k https://10.0.2.10:6443/version  # Control plane 1
time curl -k https://10.0.3.10:6443/version  # Control plane 2
time curl -k https://10.0.4.10:6443/version  # Control plane 3
```

## Notes
- AWS user_data that is used for init-control-plane.sh.tmpl has a size limit of 16,384
- Remove the echo join commands in init-control-plane.sh.tmpl and init-worker-node.sh when using in production or just delete the /var/log/k8s-install-success.txt found in all control planes

## Sample Output
<img width="556" alt="Image" src="https://github.com/user-attachments/assets/2e7e5f8b-0bd9-46e4-8ae9-2377f4052079" />

<img width="889" alt="Image" src="https://github.com/user-attachments/assets/b226fa2b-9c1d-40fb-a568-c56eb4f3a664" />