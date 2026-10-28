variable "application" { type = string }
variable "environment" { type = string }
variable "ecr_image_uri" {
  description = "Full ECR image URI including tag (e.g., 123456.dkr.ecr.us-west-2.amazonaws.com/repo:latest)"
  type        = string
}
variable "s3_bucket_arn" { type = string }
variable "s3_bucket_name" { type = string }
variable "bedrock_model_id" {
  description = "Bedrock model ID for Haiku (e.g., anthropic.claude-haiku-5-5)"
  type        = string
  default     = "us.anthropic.claude-haiku-5-5"
}
variable "log_level" {
  type    = string
  default = "INFO"
}

variable "max_lambda_memory_mb" {
  description = "Maximum memory (MB) allowed for any Lambda function. Prevents cost runaway."
  type        = number
  default     = 1024

  validation {
    condition     = var.max_lambda_memory_mb <= 2048
    error_message = "Lambda memory cannot exceed 2048 MB for this assessment."
  }
}

variable "max_lambda_timeout_seconds" {
  description = "Maximum timeout (seconds) allowed for any Lambda function."
  type        = number
  default     = 300

  validation {
    condition     = var.max_lambda_timeout_seconds <= 300
    error_message = "Lambda timeout cannot exceed 300 seconds (5 minutes) for this assessment."
  }
}
