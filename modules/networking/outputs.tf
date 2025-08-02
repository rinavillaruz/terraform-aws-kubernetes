output "vpc_id" {
  description = "ID of the VPC for the Kubernetes cluster"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC for security group rules and network configuration"
  value       = aws_vpc.main.cidr_block
}

output "private_subnets" {
  description = "Private subnets for Kubernetes worker nodes and internal services"
  value       = aws_subnet.private_subnets
}

output "public_subnets" {
  description = "Public subnets for load balancers, bastion hosts, and internet-facing resources"
  value       = aws_subnet.public_subnets
}