variable aws_region {
    type = map
    default = {
        "development" = "us-east-1"
        "production" = "us-east-2"
    }
}

variable "public_subnet_cidrs" {
    type        = list(string)
    description = "Public Subnet CIDR values"
    default     = ["10.0.1.0/24"]
}
 
variable "private_subnet_cidrs" {
    type        = list(string)
    description = "Private Subnet CIDR values"
    default     = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
    type = map
    description = "Availability Zones"
    default = {
        "development" = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d","us-east-1f"]
        "production" = ["us-east-2a","us-east-2b","us-east-2c","us-east-2d","us-east-2f"]
    }
}