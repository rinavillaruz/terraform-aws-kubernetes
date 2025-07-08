variable "public_subnet_cidrs" {
    type        = list(string)
    description = "Public Subnet CIDR values"
    default     = ["10.0.1.0/24"]
}

variable "control_plane_private_ips" {
  default = ["10.0.2.10", "10.0.3.10", "10.0.4.10"]
  type        = list(string)
  description = "List of private IPs for control plane nodes"
}

variable "bastion" {
    type = map
    default = {
        "ami"           =   "ami-084568db4383264d4"
        "instance_type" =   "t3.micro"
        "private_ip"    =   "10.0.1.10"
        "name"          =   "Bastion Host"
    }
}

variable "common_functions" {
    type = any
    default = {
        "source"        =   "scripts/common-functions.sh"
        "destination"   =   "/tmp/common-functions.sh"
        "connection"    =   {
            "type"          =   "ssh"
            "user"          =   "ubuntu"
            "bastion_user"  =   "ubuntu"
            "timeout"       =   "30m" # Allow enough time for installation
        }
    }
}

variable "control_plane" {
    type = any
    default = {
        "ami"               =   "ami-084568db4383264d4"
        "instance_type"     =   "t3.xlarge"
        "root_block_device" =   {
            "volume_size"           = 20
            "volume_type"           = "gp3"
            "delete_on_termination" = true
        }
        "init_file"     =   "scripts/init-control-plane.sh.tmpl"
        "name"          =   "Control Plane 1"
    }
}

variable "wait_for_master_ready" {
    type = map
    default = {
        "source" = "scripts/wait-for-master.sh.tmpl"
    }
}

variable "control_plane_secondary" {
    type = any
    default = {
        "ami"               =   "ami-084568db4383264d4"  # Replace with a Ubuntu 12 AMI ID
        "instance_type"     =   "t3.xlarge"
        "root_block_device" =   {
            "volume_size"           = 20
            "volume_type"           = "gp3"
            "delete_on_termination" = true
        }
        "init_file"         =   "scripts/init-control-plane.sh.tmpl"
        "name"              =   "Control Plane 1"
    }
}

variable "worker_nodes" {
    type = any
    default = {
        "count"         =   3
        "ami"           =   "ami-084568db4383264d4"
        "instance_type" =   "t3.large"
        "root_block_device" = {
            "volume_size"           = 20
            "volume_type"           = "gp3"
            "delete_on_termination" = true
        }
        "init_file"     =   "scripts/init-worker-node.sh.tmpl"
        "name"          =   "Worker Node"
    }
}

variable "wait_for_workers_to_join" {
    type = map
    default = {
        "init_file" =   "scripts/wait-for-workers.sh.tmpl"
        "log_file"  =   "/var/log/k8s-wait-for-workers-$(date +%Y%m%d-%H%M%S).log"
    }
}

variable "label_worker_nodes" {
    type = any
    default = {
        "init_file" = "scripts/label-worker-nodes.sh.tmpl"
        "expected_worker_count" = 3
    }
}

// FROM Other Module
variable "vpc_id" {
  description = "VPC ID from AWS module"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets from AWS module"
  type        = any
}

variable "public_subnets" {
  description = "Public subnets from AWS module"
  type        = any
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID"
  type        = string
}

variable "control_plane_security_group_id" {
  description = "Control plane security group ID"
  type        = string
}

variable "worker_node_security_group_id" {
  description = "Worker node security group ID"
  type        = string
}

variable "kubernetes_master_instance_profile" {
  description = "IAM instance profile for master nodes"
  type        = string
}

variable "kubernetes_worker_instance_profile" {
  description = "IAM instance profile for worker nodes"
  type        = string
}

variable "tls_private_key_pem" {
  description = "TLS private key"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "Key pair name"
  type        = string
}