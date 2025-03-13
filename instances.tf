
# ~~~~~~~~~~~~~~~~~~~ Use data source to get a registered Amazon Linux 2 ami ~~~~~~~~~~~~~~~~~~~~~~ #

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


# ~~~~~~~~~~~~~~~~~~ Create an ec2 instance for the Jenkins server and agents ~~~~~~~~~~~~~~~~~~~~~ #

locals {
  servers = {
    agent-1        = {name = "jenkins-server-agent1", instance-type = "${var.instance_node_type}", userdata = "${file("agents-userdatas.sh")}", security_group_ids = ["${aws_security_group.ec2_allow_rule_agent.id}"]},
    agent-2        = {name = "jenkins-server-agent2", instance-type = "${var.instance_node_type}", userdata = "${file("agents-userdatas.sh")}", security_group_ids = ["${aws_security_group.ec2_allow_rule_agent.id}"]},
    jenkins-server = {name = "jenkins-server", instance-type = "${var.instance_type}", userdata = "${file("jenkins-server-userdata.sh")}", security_group_ids = ["${aws_security_group.ec2_allow_rule.id}"]},
  }
}

resource "aws_instance" "ec2-instance" {
  for_each = local.servers
  ami                    = data.aws_ami.amazon_linux_2.id
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


