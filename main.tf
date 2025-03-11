
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

# Generate a secure key using a rsa algorithm

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Creating the keypair in aws

resource "aws_key_pair" "ec2_key" {
  key_name   = var.keypair_name                 
  public_key = tls_private_key.ec2_key.public_key_openssh 
}

# Save the .pem file locally for remote connection

resource "local_file" "ssh_key" {
  filename        = var.keypair_location
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0400"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~ Security group for the jenkins server ~~~~~~~~~~~~~~~~~~~~~~ #

resource "aws_security_group" "ec2_allow_rule" {

  ingress {
    from_port   = 8080
    to_port     = 8080
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~ Security group for the jenkins agents ~~~~~~~~~~~~~~~~~~~~~~ #

resource "aws_security_group" "ec2_allow_rule_agent" {

  ingress {
    from_port   = 3000
    to_port     = 3000
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

# ~~~~~~~~~~~~~~~~~~~~~~~~ Create the bucket ~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_s3_bucket" "bucket1" {

  bucket = var.bucket_name
  force_destroy = true
  
}

# ~~~~~~~~~~~ Configure ownership parameters in the bucket ~~~~~~~~~~~~

resource "aws_s3_bucket_ownership_controls" "rule" {

  bucket = aws_s3_bucket.bucket1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

}

resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.bucket1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}
resource "aws_s3_bucket_acl" "bucket1-acl" {

  bucket = aws_s3_bucket.bucket1.id
  acl    = "private"

  depends_on = [ aws_s3_bucket_ownership_controls.rule, aws_s3_bucket_public_access_block.bucket_access_block,aws_s3_bucket_acl.bucket1-acl]

}

# ~~~~~~~~~~~~~~~~~ Upload the site content in the bucket ~~~~~~~~~~~~~

resource "null_resource" "upload_files" {

  provisioner "local-exec"  {
      command = <<EOT
       
        aws s3 sync ${var.cp-path} s3://${aws_s3_bucket.bucket1.bucket}/ 
      EOT
      interpreter = [
      "bash",
      "-c"
    ]
  }

depends_on = [aws_s3_bucket.bucket1 , null_resource.generate_s3_mount_script]
 
}

# ~~~~~~~~~~~~~~~~~~~ Configure The Bucket policy ~~~~~~~~~~~~~~~~~~

data aws_iam_policy_document "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document "s3_read_access" {
  statement {
    actions = ["s3:Get*", "s3:List*"]

    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"

  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

resource "aws_iam_role_policy" "join_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name       = "join_policy"
  role       = "${aws_iam_role.ec2_iam_role.name}"

  policy = "${data.aws_iam_policy_document.s3_read_access.json}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = "${aws_iam_role.ec2_iam_role.name}"
}

# ~~~~~~~~~~~~~~~~ Generate ascript to mount the S3 ~~~~~~~~~~~~ #

resource "null_resource" "generate_s3_mount_script" {

  provisioner "local-exec" {
    command = templatefile("mount-s3.tpl", {
      s3_bucket_id  = aws_s3_bucket.bucket1.id
    })
    interpreter = [
      "bash",
      "-c"
    ]
    }
    depends_on = [ aws_s3_bucket.bucket1 ]
}

# ~~~~~~~~~~~~~~~~~~ Create an ec2 instance for the Jenkins server and agents ~~~~~~~~~~~~~~~~~~~~~ #

locals {
  servers = {
    agent-1        = {name = "jenkins-server-agent1", instance-type = "${var.instance_node_type}", userdata = "${file("userdatas.sh")}", security_group_ids = ["${aws_security_group.ec2_allow_rule_agent.id}"]},
    agent-2        = {name = "jenkins-server-agent2", instance-type = "${var.instance_node_type}", userdata = "${file("userdatas.sh")}", security_group_ids = ["${aws_security_group.ec2_allow_rule_agent.id}"]},
    jenkins-server = {name = "jenkins-server", instance-type = "${var.instance_type}", userdata = "${file("userdata.sh")}", security_group_ids = ["${aws_security_group.ec2_allow_rule.id}"]},
  }
}

resource "aws_instance" "ec2-instance" {
  for_each = local.servers
  ami                    = var.aws_ami
  instance_type          = each.value.instance-type
  subnet_id              = aws_subnet.subnet-public-1.id
  vpc_security_group_ids = each.value.security_group_ids
  key_name               = aws_key_pair.ec2_key.key_name
  user_data              = each.value.userdata
  iam_instance_profile   = "${aws_iam_instance_profile.instance_profile.name}"
  depends_on             = [ null_resource.generate_s3_mount_script , null_resource.upload_files ]
  tags = {
    Name = each.value.name
  }

 }

# ~~~~~~~~~ Create the file to config aws credentials in the Jenkins server and agents ~~~~~~~~ #

resource "null_resource" "Create_credentials_folder" {

  depends_on =[ aws_instance.ec2-instance["agent-1"] , aws_instance.ec2-instance["agent-2"], aws_instance.ec2-instance["jenkins-server"]]
  for_each = local.servers

    connection {

    type             = "ssh"
    host             = aws_instance.ec2-instance[each.key].public_ip
    user             = "ec2-user"
    private_key      = file(var.keypair_location) # Location of the Private Key
    timeout          = "5m"

    }

    provisioner "remote-exec" {
    inline = [
      "sudo mkdir ~/.aws",
      "sudo touch ~/.aws/config",
      "sudo touch ~/.aws/credentials",
    ]
  }
}

# ~~~~~~~~~~~~ Send the current aws credentials in the Jenkins server and agents ~~~~~~~~~~~~~~ #

 resource "null_resource" "send_aws_credentials" {

  depends_on =[ null_resource.Create_credentials_folder["agent-1"] , null_resource.Create_credentials_folder["agent-2"] , null_resource.Create_credentials_folder["jenkins-server"] ]
  for_each = local.servers

    connection {

    type             = "ssh"
    host             = aws_instance.ec2-instance[each.key].public_ip
    user             = "ec2-user"
    private_key      = file(var.keypair_location) # Location of the Private Key
    timeout          = "5m"

    }
 
    provisioner "file" {

    source      = "mount_s3.sh"
    destination = "mount_s3.sh"

    }

    provisioner "file" {

    source      = "~/.aws/config"
    destination = "config"

    }

    provisioner "file" {

    source      = "~/.aws/credentials"
    destination = "credentials"

    }
 }

# ~~~~~~~~~~ Run the script to mount the S3 Bucket to the Jenkins server and agents ~~~~~~~~~~~ #

resource "null_resource" "mount_s3" {

  depends_on =[null_resource.generate_s3_mount_script , null_resource.send_aws_credentials["agent-1"] , null_resource.send_aws_credentials["agent-2"] , null_resource.send_aws_credentials["jenkins-server"]]
  for_each = local.servers

    connection {
    type             = "ssh"
    host             = aws_instance.ec2-instance[each.key].public_ip
    user             = "ec2-user"
    private_key      = file(var.keypair_location) # Location of the Private Key
    timeout          = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir ~/.aws",
      "sudo mv config ~/.aws/config",
      "sudo mv credentials ~/.aws/credentials",
      "sudo chmod +x mount_s3.sh",
      "bash mount_s3.sh",
    ]
  }
}

# ~~~~~~~~~~~~~~~~ To delete the files while destroying this infrastructure ~~~~~~~~~~~~ #

resource "null_resource" "clean_up" {

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ec2-key-1.pem mount_s3.sh"
  }
}

# ~~~~~~~~~~~~~~~~ Print the link to be redirected to the jenkins server ~~~~~~~~~~~~~~~ #

output "INFO" {
  value = "AWS Resources and Jenkins Server has been provisioned. Go to http://${aws_instance.ec2-instance["agent-1"].public_ip}:3000"
}

output "INFO-1" {
  value = "AWS Resources and Jenkins Server has been provisioned. Go to http://${aws_instance.ec2-instance["agent-2"].public_ip}:3000"
}

output "INFO-2" {
  value = "AWS Resources and Jenkins Server has been provisioned. Go to http://${aws_instance.ec2-instance["jenkins-server"].public_ip}:8080"
}

