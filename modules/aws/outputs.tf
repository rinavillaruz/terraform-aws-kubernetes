output "private_key_path" {
  value = local_file.private_key.filename
}

output "public_key" {
  value     = tls_private_key.example.public_key_openssh
  sensitive = true
}

output "current_workspace" {
  value = terraform.workspace
}