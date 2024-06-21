terraform {
  backend "s3" {
    # use the bucket name from the backend.tfvars file
  }
}

provider "aws" {
  region = var.aws_region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# if use cloudfront, create provider "aws" for cloudfront here
