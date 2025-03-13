
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Configure the AWS provider

provider "aws" {
  region = var.region
  default_tags {
   tags = {
     Environment = "Test"
     Owner       = "Darelle"
     Project     = "Mount-S3-to-ec2"
   }
 }
}