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
