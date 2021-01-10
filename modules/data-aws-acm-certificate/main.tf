# Always use the us-east-1 region (required for Cloudfront distribution)
provider "aws" {
  region = "us-east-1"
}

data "aws_acm_certificate" "cert" {
  domain = var.domain
}