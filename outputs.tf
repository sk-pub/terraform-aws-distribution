# Output variable definitions

output "app_bucket_arn" {
  description = "ARN of the app bucket"
  value       = module.website_s3_bucket.arn
}

output "app_bucket_name" {
  description = "Name (id) of the app bucket"
  value       = module.website_s3_bucket.name
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.primary.name_servers
}
