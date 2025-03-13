#!/bin/bash -x

#### Author: Utrains
#### Date: 13-03-2025

sudo yum update -y

sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo yum upgrade -y

## Install and Enable Docker
sudo yum install docker -y
sudo service docker start 
sudo systemctl enable docker.service

sudo chmod 777  /var/run/docker.sock


## install Git
sudo yum install git -y
yum install unzip -y

## Install Java 11:
#sudo amazon-linux-extras install java-openjdk11 -y

sudo yum install java-11* -y

## Install Jenkins then Enable the Jenkins service to start at boot :
sudo yum install jenkins -y
sudo systemctl enable jenkins

## Start Jenkins as a service:
sudo systemctl start jenkins

## Display Initial Jenkins Password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

## Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo  ./aws/install

## Install Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform


