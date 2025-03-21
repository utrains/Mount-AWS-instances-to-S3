cat << EOF >> mount_s3.sh
#!/bin/bash 
sudo yum update -y
sudo yum upgrade -y

## Install S3 Mount
wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
sudo yum install ./mount-s3.rpm -y
rm -f ./mount-s3.rpm

## Create mount point directory
mkdir -p ~/mount_s3
mount-s3 ${s3_bucket_id} ~/mount_s3

# Ensure mount persists across reboots
(crontab -l 2>/dev/null; echo "@reboot mount-s3 mont-s3-lab ~/mount_s3") | crontab -
echo "${s3_bucket_id} ~/mount_s3 _netdev,allow_other 0 0" | sudo tee -a /etc/fstab

## Verify if the Bucket has been well mounted
df -h 
ls ~/mount_s3

EOF
