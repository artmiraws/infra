output "state_bucket_name" {
  description = "Name of the S3 bucket that stores remote state."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket that stores remote state."
  value       = aws_s3_bucket.state.arn
}

output "backend_config" {
  description = "Backend setting to pass to `tofu init -backend-config`."
  value       = "bucket=${aws_s3_bucket.state.bucket}"
}
