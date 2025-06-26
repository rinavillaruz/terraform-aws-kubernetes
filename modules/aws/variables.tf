variable aws_region {
    type = map
    default = {
        "development" = "us-east-1"
        "production" = "us-east-2"
    }
}

variable "public_subnet_cidrs" {
    type        = list(string)
    description = "Public Subnet CIDR values"
    default     = ["10.0.1.0/24"]
}
 
variable "private_subnet_cidrs" {
    type        = list(string)
    description = "Private Subnet CIDR values"
    default     = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
    type = map
    description = "Availability Zones"
    default = {
        "development" = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d","us-east-1f"]
        "production" = ["us-east-2a","us-east-2b","us-east-2c","us-east-2d","us-east-2f"]
    }
}

variable "ami_bastion" {
    type = map
    default = {
        "development" = "ami-dev"
        "production" = "ami-prod"
    }
}

variable "instance_type_bastion" {
    type = map
    default = {
        "development" = "t3.micro"
        "production" = "t3.micro"
    }
}

variable "public_subnet_alb_cidrs" {
  type        = list(string)
  description = "Public Subnet ALB CIDR values"
  default     = ["10.0.7.0/24", "10.0.8.0/24"]  # Two public subnets
}

variable "control_plane_private_ips" {
  default = ["10.0.2.10", "10.0.3.10", "10.0.4.10"]
  type        = list(string)
  description = "List of private IPs for control plane nodes"
}

variable "kubeadm_join_command" {
  type        = string
  description = "Kubeadm join command for Kubernetes cluster setup"
  default     = "NONE-SSM"
}