#!/bin/bash -x
sudo yum update -y
sudo yum upgrade -y

## Install Jenkins 
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

## Install Java 11:
sudo yum install java-11* -y

## Install Jenkins then Enable the Jenkins service to start at boot :
sudo yum install jenkins -y
sudo systemctl enable jenkins

## Start Jenkins as a service:
sudo systemctl start jenkins

## Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo  ./aws/install

## Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl status docker
sudo usermod -aG docker jenkins
sudo chmod 777 /var/run/docker.sock
docker ps

## Install Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform


