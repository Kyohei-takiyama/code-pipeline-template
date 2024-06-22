##############################################
# data
##############################################
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

##############################################
# Variables
##############################################
variable "prefix" {
  default = "codepipeline-sample"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-west-2"
}

variable "aws_access_key" {
  description = "The AWS access key to use"
}

variable "aws_secret_key" {
  description = "The AWS secret key to use"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  default = "10.0.0.0/24"
}

variable "private_subnet_cidr_block" {
  default = "10.0.64.0/24"
}

variable "subnets" {
  type = map(any)
  default = {
    private_subnets = {
      private-1a = {
        name = "private-1a",
        cidr = "10.0.65.0/24",
        az   = "us-west-2a"
      },
      private-1b = {
        name = "private-1b",
        cidr = "10.0.66.0/24",
        az   = "us-west-2b"
      },
    },
    public_subnets = {
      public-1a = {
        name = "public-1a"
        cidr = "10.0.1.0/24"
        az   = "us-west-2a"
      },
      public-1b = {
        name = "public-1b"
        cidr = "10.0.2.0/24"
        az   = "us-west-2b"
      }
    }
  }
}

variable "main_domain" {
}

variable "sub_domain" {
}

variable "zone_id" {
}

variable "image" {
  default = "nginx:latest"
}

variable "github_token" {
}

variable "github_owner" {
}

variable "github_repo" {
}

variable "container_name" {
  default = "nginx"
}
