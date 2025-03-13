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
