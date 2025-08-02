provider "aws" {
  region = lookup(var.aws_region, terraform.workspace)
}

resource "aws_vpc" "main" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  
  tags = {
    Name                = "${terraform.workspace} - Kubernetes Cluster VPC"
    Environment         = terraform.workspace
    Purpose             = "Kubernetes Infrastructure"
  }
}

resource "aws_subnet" "public_subnets" {
  count               = length(var.public_subnet_cidrs)
  vpc_id              = aws_vpc.main.id
  cidr_block          = element(var.public_subnet_cidrs, count.index)
  availability_zone   = element(var.azs[terraform.workspace], count.index)

  tags = {
    Name              = "${terraform.workspace} - Public Subnet ${count.index + 1}"
    Description       = "Public subnet for bastion host and load balancers"
    Type              = "Public"
    Environment       = terraform.workspace
    AvailabilityZone  = element(var.azs[terraform.workspace], count.index)
    Purpose           = "DMZ"
    ManagedBy         = "Terraform"
    Project           = "Kubernetes"
    Tier              = "DMZ"  # Demilitarized Zone
  }
}

resource "aws_subnet" "private_subnets" {
  count               = min(length(var.private_subnet_cidrs), length(var.azs[terraform.workspace]))
  vpc_id              = aws_vpc.main.id
  cidr_block          = var.private_subnet_cidrs[count.index]
  availability_zone   = var.azs[terraform.workspace][count.index] # Ensures 1 AZ per subnet

  tags = {
    Name              = "${terraform.workspace} - Private Subnet ${count.index + 1}"
    Description       = "Private subnet for Kubernetes worker and control plane nodes"
    Type              = "Private"
    Environment       = terraform.workspace
    AvailabilityZone  = var.azs[terraform.workspace][count.index]
    Purpose           = "Kubernetes Nodes"
    ManagedBy         = "Terraform"
    Project           = "Kubernetes"
    Tier              = "Internal"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${terraform.workspace} - Internet Gateway"
    Purpose     = "Internet access for public subnets"
    Description = "Provides internet connectivity for bastion host and load balancers"
    Type        = "Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${terraform.workspace} - Public Route Table"
    Description = "Route table for public subnets - directs traffic to internet gateway"
    Type        = "Public"
    Purpose     = "Internet routing for DMZ resources"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    Tier        = "DMZ"
    RouteType   = "Internet-bound"
    Project     = "Kubernetes"
  }
}

# Add a default route to the internet gateway in the public route table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate only the first public subnet with the public route table
resource "aws_route_table_association" "public_first_subnet" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name        = "${terraform.workspace} - NAT Gateway EIP"
    Description = "Elastic IP for NAT Gateway - enables internet access for private subnets"
    Purpose     = "NAT Gateway"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name        = "${terraform.workspace} - NAT Gateway"
    Description = "NAT Gateway for private subnet internet access - enables Kubernetes nodes to reach external services"
    Purpose     = "Private Subnet Internet Access"
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${terraform.workspace} - Private Route Table"
    Description = "Route table for private subnets - directs internet traffic through NAT Gateway"
    Type        = "Private"
    Environment = terraform.workspace
    Purpose     = "NAT Gateway Routing"
    ManagedBy   = "Terraform"
  }
}

# Add a route in the private route table to direct internet traffic through the NAT Gateway.
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Link private subnets to the private route table.
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private.id
}