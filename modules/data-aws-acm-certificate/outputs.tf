# Output variable definitions

output "arn" {
  description = "ARN of the certificate"
  value       = data.aws_acm_certificate.cert.arn
}
