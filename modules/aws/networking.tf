provider "aws" {
  region = lookup(var.aws_region, terraform.workspace)
}

# VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "${terraform.workspace} Kubernetes VPC"
    }
}

# Only one public subnet for Bastion host
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs[terraform.workspace], count.index)

  tags = {
    Name = "${terraform.workspace} - Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = min(length(var.private_subnet_cidrs), length(var.azs[terraform.workspace]))
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[terraform.workspace][count.index] # Ensures 1 AZ per subnet

  tags = {
    Name = "${terraform.workspace} - Private Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "public_subnets_alb" {
  count                   = 2  # Create only two subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_alb_cidrs[count.index]
  availability_zone       = var.azs[terraform.workspace][count.index] # Ensures each subnet is in a different AZ
  map_public_ip_on_launch = true  # Enables public access for instances

  tags = {
    Name = "${terraform.workspace} - Public Subnet ALB ${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace} - Internet Gateway"
  }
}

# Create a route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace} - Public Route Table"
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

# NAT Gateway
# Elastic IP fot NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${terraform.workspace} - NAT EIP"
  }
}

# Create the NAT Gateway in the first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${terraform.workspace} - NAT Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace} - Private Route Table"
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