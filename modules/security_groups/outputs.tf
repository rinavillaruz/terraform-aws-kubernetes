output "bastion_security_group_id" {  
  description = "Security group ID for the bastion host - used for SSH access to cluster nodes"
  value       = aws_security_group.bastion.id
}

output "control_plane_security_group_id" {  
  description = "Security group ID for Kubernetes control plane nodes - manages API server and cluster components"
  value       = aws_security_group.control_plane.id
}

output "worker_node_security_group_id" {  
  description = "Security group ID for Kubernetes worker nodes - handles application workloads and pod traffic"
  value       = aws_security_group.worker_node.id
}