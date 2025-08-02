resource "aws_ssm_parameter" "join_command" {
  name        = "/k8s/control-plane/join-command"
  type        = "SecureString"
  value       = "placeholder-will-be-updated-by-script"
  description = "Kubernetes cluster join command for worker nodes - automatically updated by control plane initialization script"
  
  lifecycle {
    ignore_changes = [value] # Let the script update the value
  }
}