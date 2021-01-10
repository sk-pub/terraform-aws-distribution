# Terraform configuration

# Create a bucket
resource "aws_s3_bucket" "s3_app_bucket" {
  bucket = var.bucket_name

  acl    = "public-read"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket_name}/*"
            ]
        }
    ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = var.tags
}

# `template_files` module among other things calculates content type.
# Thus, it's convenient to use it to list files for uploading to S3
module "template_files" {
  source = "hashicorp/dir/template"
  version = "1.0.2"
  base_dir = "${path.module}/www"
}

# Upload content of the www folder
resource "aws_s3_bucket_object" "content" {
  for_each = module.template_files.files
  bucket = aws_s3_bucket.s3_app_bucket.id
  key = each.key
  content_type = each.value.content_type
  source  = each.value.source_path
  content = each.value.content
  etag = each.value.digests.md5
}
