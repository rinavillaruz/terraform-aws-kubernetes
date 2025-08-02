variable "public_subnet_cidrs" {
    type        = list(string)
    description = "Public Subnet CIDR values"
    default     = ["10.0.1.0/24"]
}

variable "control_plane_private_ips" {  
  type        = list(string)
  description = "List of private IPs for control plane nodes"
  default     = ["10.0.2.10", "10.0.3.10", "10.0.4.10"]
}

variable "bastion" {
  description = "Configuration for the bastion host used as a secure gateway to access private cluster resources"
  type = map
  default = {
      "ami"           =   "ami-084568db4383264d4"
      "instance_type" =   "t3.micro"
      "private_ip"    =   "10.0.1.10"
      "name"          =   "Bastion Host"
  }
}

variable "common_functions" {
  description = "Configuration for deploying shared utility scripts across all cluster instances"
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
  description = "Configuration for the primary Kubernetes control plane node including API server, scheduler, and controller manager"
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
  description = "Configuration for the script that waits for the control plane to be fully operational before proceeding with cluster setup"
  type = map
  default = {
      "source" = "scripts/wait-for-master.sh.tmpl"
  }
}

variable "control_plane_secondary" {
  description = "Configuration for additional control plane nodes to provide high availability for the Kubernetes cluster"
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
  description = "Configuration for Kubernetes worker nodes that run application workloads and pods"
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
  description = "Configuration for the script that waits for all worker nodes to successfully join the Kubernetes cluster"
  type = map
  default = {
      "init_file" =   "scripts/wait-for-workers.sh.tmpl"
      "log_file"  =   "/var/log/k8s-wait-for-workers-$(date +%Y%m%d-%H%M%S).log"
  }
}

variable "label_worker_nodes" {
  description = "Configuration for applying labels and taints to worker nodes for workload scheduling and node organization" 
  type = any
  default = {
      "init_file" = "scripts/label-worker-nodes.sh.tmpl"
      "expected_worker_count" = 3
  }
}

# FROM Other Module
variable "vpc_id" {
  description = "VPC ID from AWS module where the Kubernetes cluster will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets from AWS module for deploying worker nodes and internal cluster components"
  type        = any
}

variable "public_subnets" {
  description = "Public subnets from AWS module for deploying bastion host and load balancers"  
  type        = any
}

variable "bastion_security_group_id" {
  description = "Security group ID for the bastion host allowing SSH access from authorized sources"
  type        = string
}

variable "control_plane_security_group_id" {
  description = "Security group ID for control plane nodes allowing Kubernetes API and inter-node communication"  
  type        = string
}

variable "worker_node_security_group_id" {
  description = "Security group ID for worker nodes allowing pod-to-pod communication and kubelet access" 
  type        = string
}

variable "kubernetes_master_instance_profile" {
  description = "IAM instance profile for control plane nodes with permissions for Kubernetes master operations"  
  type        = string
}

variable "kubernetes_worker_instance_profile" {
  description = "IAM instance profile for worker nodes with permissions for Kubernetes worker operations"  
  type        = string
}

variable "tls_private_key_pem" {
  description = "TLS private key in PEM format for secure communication within the Kubernetes cluster"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "AWS EC2 key pair name for SSH access to cluster instances"
  type        = string
}