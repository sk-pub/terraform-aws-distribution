# Terraform configuration

provider "aws" {
  region = "eu-central-1"
}

module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"

  bucket_name = "sk-aws-s3-static-website-bucket-test-2021-01-10"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
