output "debug_private_key_path_from_module" {
  value = local_file.private_key
}

output "debug_public_key_path_from_module" {
  value = aws_key_pair.generated_key.public_key
}

output "debug_network_lb_dns" {
  value = aws_lb.k8s_api.dns_name
}

output "debug_join_command" {
  description = "Join command from SSM Parameter Store"
  value       = aws_ssm_parameter.join_command.value
}

output "control_plane_private_ips" {
  description = "Private IP addresses of all control plane nodes"
  value       = values(aws_instance.control_plane)[*].private_ip
}

output "control_plane_master_ip" {
  description = "Private IP address of the master control plane node"
  value       = aws_instance.control_plane["0"].private_ip
}