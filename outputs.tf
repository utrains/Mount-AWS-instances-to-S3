# ~~~~~~~~~~~~~~~~ Print the link to be redirected to the jenkins server ~~~~~~~~~~~~~~~ #

output "INFO" {
  value = "AWS Resources and agent-1 has been provisioned. Go to http://${aws_instance.ec2-instance["agent-1"].public_ip}:80"
}

output "INFO-1" {
  value = "AWS Resources and agent-2 has been provisioned. Go to http://${aws_instance.ec2-instance["agent-2"].public_ip}:80"
}

output "INFO-2" {
  value = "AWS Resources and Jenkins Server has been provisioned. Go to http://${aws_instance.ec2-instance["jenkins-server"].public_ip}:8080"
}

# print the URL of the Jenkins server

output "ssh_connection_command_for_agent-1" {
  value     = "ssh -i ${var.keypair_location} ec2-user@${aws_instance.ec2-instance["agent-1"].public_ip}"
}

output "ssh_connection_command_for_agent-2" {
  value     = "ssh -i ${var.keypair_location} ec2-user@${aws_instance.ec2-instance["agent-2"].public_ip}"
}

output "ssh_connection_command_for_jenkins-server" {
  value     = "ssh -i ${var.keypair_location} ec2-user@${aws_instance.ec2-instance["jenkins-server"].public_ip}"
}