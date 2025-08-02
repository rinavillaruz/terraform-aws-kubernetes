# Generate an RSA key pair
resource "tls_private_key" "private" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key-pair"
  public_key = tls_private_key.private.public_key_openssh
}

# Save the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.private.private_key_pem
  filename = "${path.root}/terraform-key-pair.pem"
}