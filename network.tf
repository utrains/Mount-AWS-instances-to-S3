# The below code is for creating a vpc

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  instance_tenancy     = "default"
}

# Create Public Subnet for the jenkins server

resource "aws_subnet" "subnet-public-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ1

}

# Create IGW for internet connection 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

# Creating Route table 

resource "aws_route_table" "public-routetab" {
  vpc_id = aws_vpc.vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.igw.id
  }

}

# Associating route tabe to public subnet

resource "aws_route_table_association" "public-routetab-subnet-1" {
  subnet_id      = aws_subnet.subnet-public-1.id
  route_table_id = aws_route_table.public-routetab.id

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~ Security group for the jenkins server ~~~~~~~~~~~~~~~~~~~~~~ #

resource "aws_security_group" "ec2_allow_rule" {

  # allow access on port 8080 for Jenkins Server
  
  ingress {
    description      = "http proxy access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }

}

# ~~~~~~~~~~~~~~~~~~~~~~~~~ Security group for the jenkins agents ~~~~~~~~~~~~~~~~~~~~~~ #

resource "aws_security_group" "ec2_allow_rule_agent" {

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }

}