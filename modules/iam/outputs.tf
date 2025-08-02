output "kubernetes_master_instance_profile" {  
  description = "IAM instance profile name for Kubernetes control plane nodes - provides AWS API permissions"
  value       = aws_iam_instance_profile.kubernetes_master.name
}

output "kubernetes_worker_instance_profile" {  
  description = "IAM instance profile name for Kubernetes worker nodes - provides AWS API permissions for pods and services"
  value       = aws_iam_instance_profile.kubernetes_worker.name
}