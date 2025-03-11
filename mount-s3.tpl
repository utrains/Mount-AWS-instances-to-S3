cat << EOF >> mount_s3.sh
#!/bin/bash -x
sudo yum update -y
sudo yum upgrade -y

## Install S3 Mount
wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
sudo yum install ./mount-s3.rpm -y
rm -f ./mount-s3.rpm

## Create mount point directory
sudo mkdir /mount_s3
sudo mount-s3 ${s3_bucket_id} /mount_s3

EOF
