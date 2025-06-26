output "debug_private_key_path_from_module" {
  value = lookup(local.modules, terraform.workspace, null).debug_private_key_path_from_module
  sensitive = true
}

output "debug_public_key_path_from_module" {
  value = lookup(local.modules, terraform.workspace, null).debug_public_key_path_from_module
}

output "debug_network_lb_dns" {
  value = lookup(local.modules, terraform.workspace, null).debug_network_lb_dns
}

output "debug_join_command" {
  description = "Join command from SSM Parameter Store"
  value = lookup(local.modules, terraform.workspace, null).debug_join_command
  sensitive = true
}