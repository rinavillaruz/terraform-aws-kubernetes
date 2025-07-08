output "kubernetes_master_instance_profile" {
  value = aws_iam_instance_profile.kubernetes_master.name
}

output "kubernetes_worker_instance_profile" {
  value = aws_iam_instance_profile.kubernetes_worker.name
}