

variable "region" {
  type = string
  default = "us-east-2"
}

variable "keypair_name" {
  type = string
  default = "ec2-key-1"
}

variable "keypair_location" {
  type = string
  default = "ec2-key-1.pem"
}

variable "vpc_cidr" {
  type = string
  default = "192.168.0.0/16"
}

variable "AZ1" {
  type = string
  default = "us-east-2a"
}

variable "subnet1_cidr" {
  type = string
  default = "192.168.1.0/24"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "instance_node_type" {
  type = string
  default = "t3.small"
}

variable "bucket_name" {
    type = string
    description = "The name of the your bucket"
    default = "mont-s3-lab"   
}

variable "cp-path" {
  type = string
  description = "PATH where the files are located"
  default = "Restaurantly"
}