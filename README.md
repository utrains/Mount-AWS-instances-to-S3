# Mounting an S3 Bucket to Multiple EC2 Instances Using Terraform

## Project Overview
This project demonstrates how to use Terraform to provision multiple EC2 instances and configure them to mount a shared Amazon S3 bucket as a file system using the `mount-s3.rpm` package. This setup enables the EC2 instances to access and share data stored in the S3 bucket as if it were a local directory.

## Objective
The objective of this project is to:
- Provision multiple EC2 instances using Terraform.
- Configure these instances to mount a shared S3 bucket as a file system.
- Use the `mount-s3.rpm` package to facilitate the mounting process.
- Ensure persistence and validate the setup with file operations.

## Project Description

### 1. Provisioning AWS Infrastructure with Terraform
- Create an S3 bucket for shared storage.
- Launch multiple EC2 instances using Terraform.
- Define IAM roles and policies to grant EC2 instances the required permissions to access the S3 bucket.

### 2. Installing and Configuring `mount-s3.rpm` on EC2 Instances
- Use Terraform user data scripts to install `mount-s3.rpm`.
- Configure system settings to mount the S3 bucket at a designated directory (e.g., `/mnt/s3bucket`).

### 3. Mounting the S3 Bucket on All EC2 Instances
- Use the `mount-s3` command to attach the bucket to the EC2 instances.
- Ensure persistence across reboots by updating `/etc/fstab`.

### 4. Testing and Validation
- Verify that the S3 bucket is successfully mounted on all EC2 instances.
- Test file read/write operations to ensure proper functionality.

## Technologies Used
- **Terraform** – Infrastructure as Code (IaC) for automating AWS resource provisioning.
- **AWS S3** – Object storage for shared data access.
- **AWS EC2** – Compute instances for running workloads.
- **IAM Roles & Policies** – Secure access permissions for S3.
- **mount-s3.rpm** – A package that enables mounting S3 as a file system on Linux.

## Getting Started
1. Install Terraform and AWS CLI.
2. Clone this repository.
3. Configure AWS credentials.
4. Apply the Terraform configuration using:
   ```sh
   terraform init
   terraform apply
   ```
5. Verify the S3 bucket mount on the EC2 instances.
