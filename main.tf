# Terraform configuration

provider "aws" {
  region = "eu-central-1"
}

locals {
  app_bucket_name = "${replace(var.domain, ".", "-")}-app" # TODO: cover all unsupported bucket characters
  app_bucket_origin_id = "app_bucket"
}

# S3 bucket for the app
module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"
  bucket_name = local.app_bucket_name
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# CF distribution identity
resource "aws_cloudfront_origin_access_identity" "app_distribution" {
}

# S3 access policy document
data "aws_iam_policy_document" "app_distribution" {
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app_distribution.iam_arn]
    }
    resources = ["${module.website_s3_bucket.arn}/*"]
  }
}

# S3 access policy
resource "aws_s3_bucket_policy" "app_distribution" {
  bucket = module.website_s3_bucket.name
  policy = data.aws_iam_policy_document.app_distribution.json
}

# Get the ACM certificate data by the domain
module "data-aws-acm-certificate" {
  source = "./modules/data-aws-acm-certificate"
  domain = var.domain
}

# Cloudfront distribution
resource "aws_cloudfront_distribution" "app_distribution" {
  origin {
    domain_name = module.website_s3_bucket.bucket_regional_domain_name
    origin_id   = local.app_bucket_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app_distribution.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_root_object = "index.html"

  aliases = [var.domain,"www.${var.domain}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.app_bucket_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = ["DE"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = module.data-aws-acm-certificate.arn
    ssl_support_method = "sni-only"
  }

  depends_on = [module.website_s3_bucket, module.data-aws-acm-certificate]
}

# Route 53 public hosted zone
resource "aws_route53_zone" "primary" {
  name = var.domain
}

# Route53 record pointing at the CloudFront distribution.
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.app_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
