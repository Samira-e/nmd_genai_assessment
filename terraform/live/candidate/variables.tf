variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = var.aws_region == "us-west-2"
    error_message = "This assessment must run in us-west-2."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "nmd-codescreen"
}

variable "candidate_name" {
  description = "Your candidate name (lowercase, hyphens only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.candidate_name))
    error_message = "candidate_name must be 3-30 characters, lowercase alphanumeric and hyphens, starting with a letter."
  }
}

variable "application" {
  description = "Application name prefix — must be nmd-genai-{candidate_name}"
  type        = string

  validation {
    condition     = startswith(var.application, "nmd-genai-")
    error_message = "application must start with 'nmd-genai-' to match IAM policy scoping."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "Only the 'dev' environment is allowed for this assessment."
  }
}

variable "log_level" {
  description = "Log level for Lambda functions"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "log_level must be one of: DEBUG, INFO, WARNING, ERROR."
  }
}

variable "bedrock_model_id" {
  description = "Bedrock model ID for Haiku — passed to Lambda as BEDROCK_MODEL_ID env var"
  type        = string
  default     = "us.anthropic.claude-haiku-5-5"
}
