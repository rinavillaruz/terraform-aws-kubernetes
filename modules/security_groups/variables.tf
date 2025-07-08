// FROM Other Module
variable "vpc_id" {
  description = "VPC ID from AWS module"
  type        = string
}

variable "vpc_cidr_block" {
    type        = string
}