# Terraform configuration

provider "aws" {
  region = "eu-central-1"
}

locals {
  # TODO: cover all unsupported bucket characters
  app_bucket_name = "${replace(var.domain, ".", "-")}-app"
  static_bucket_name = "${replace(var.domain, ".", "-")}-static"

  app_bucket_origin_id = "app_bucket"
  static_bucket_origin_id = "static_bucket"
}

# S3 bucket for the app
module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"
  bucket_name = local.app_bucket_name
}

# S3 bucket for static content
resource "aws_s3_bucket" "s3_static" {
  bucket = local.static_bucket_name
  acl    = "private"
}

# CF distribution identity
resource "aws_cloudfront_origin_access_identity" "app_distribution" {
}

# S3 access policy documents
data "aws_iam_policy_document" "app_distribution" {
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app_distribution.iam_arn]
    }
    resources = [
      "${module.website_s3_bucket.arn}/*"
    ]
  }
}
data "aws_iam_policy_document" "static_distribution" {
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app_distribution.iam_arn]
    }
    resources = [
      "${aws_s3_bucket.s3_static.arn}/*"
    ]
  }
}

# S3 access policies
resource "aws_s3_bucket_policy" "app_distribution" {
  bucket = module.website_s3_bucket.name
  policy = data.aws_iam_policy_document.app_distribution.json
}
resource "aws_s3_bucket_policy" "static_distribution" {
  bucket = aws_s3_bucket.s3_static.id
  policy = data.aws_iam_policy_document.static_distribution.json
}

# Get the ACM certificate data by the domain
module "data-aws-acm-certificate" {
  source = "./modules/data-aws-acm-certificate"
  domain = var.domain
}

# Cloudfront distribution
resource "aws_cloudfront_distribution" "app_distribution" {
  # App bucket origin
  origin {
    domain_name = module.website_s3_bucket.bucket_regional_domain_name
    origin_id   = local.app_bucket_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app_distribution.cloudfront_access_identity_path
    }
  }
  # Static bucket origin
  origin {
    domain_name = aws_s3_bucket.s3_static.bucket_regional_domain_name
    origin_id   = local.static_bucket_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app_distribution.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_root_object = "index.html"

  aliases = [var.domain,"www.${var.domain}"]

  ordered_cache_behavior {
    # TODO: use a lambda app to ovewrite the request URL. So that the S3 bucket receives /hello.svg instead of /static/hello.svg
    path_pattern     = "static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.static_bucket_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # TODO: Optimize cache behavior for the SPA JS app (forward cookies, for example)
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

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
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

  depends_on = [module.website_s3_bucket, module.data-aws-acm-certificate, aws_s3_bucket.s3_static]
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
