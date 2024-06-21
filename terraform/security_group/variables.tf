variable "name" {
  description = "The name of the security group"
}

variable "vpc_id" {
  description = "The VPC ID to create the security group in"
}

variable "port" {
  description = "The port to open"
}

variable "cidr_blocks" {
  description = "The CIDR blocks to allow traffic from"
  type        = list(string)
}
