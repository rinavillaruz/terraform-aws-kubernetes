output "key_pair_name" {  
  description = "Name of the AWS key pair for SSH access to EC2 instances"
  value       = aws_key_pair.generated_key.key_name
}

output "tls_private_key_pem" {  
  description = "Private key in PEM format for SSH access - keep secure and do not expose"
  value       = tls_private_key.private.private_key_pem
  sensitive   = true
}