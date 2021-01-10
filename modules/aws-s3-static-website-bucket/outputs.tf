# Output variable definitions

output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.s3_app_bucket.arn
}

output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.s3_app_bucket.id
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = aws_s3_bucket.s3_app_bucket.bucket_regional_domain_name
}
