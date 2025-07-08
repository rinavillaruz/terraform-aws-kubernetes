 output "vpc_id" {
  description = "ID of the primary control plane instance"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets
}

output "public_subnets" {
  value = aws_subnet.public_subnets
}

output "vpc_cidr_block" {
    value = aws_vpc.main.cidr_block
}