output "key_pair_name" {
    value = aws_key_pair.generated_key.key_name
}

output "tls_private_key_pem" {
    value = tls_private_key.example.private_key_pem
}