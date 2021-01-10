# Output variable definitions

output "app_bucket_arn" {
  description = "ARN of the app bucket"
  value       = module.website_s3_bucket.arn
}

output "app_bucket_name" {
  description = "Name (id) of the app bucket"
  value       = module.website_s3_bucket.name
}

output "static_bucket_arn" {
  description = "ARN of the static content bucket"
  value       = aws_s3_bucket.s3_static.arn
}

output "static_bucket_name" {
  description = "Name (id) of the static content bucket"
  value       = aws_s3_bucket.s3_static.id
}

output "name_servers" {
  description = "Name servers for the primary Route 53 zone"
  value       = aws_route53_zone.primary.name_servers
}
