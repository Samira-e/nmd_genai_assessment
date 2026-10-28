terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "nmd-training-tf-states-888577066340"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
    # key is set in terraform.tfvars or via -backend-config
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Owner       = var.candidate_name
      Project     = var.application
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# =============================================================================
# S3 — Document storage
# =============================================================================
module "s3" {
  source      = "../../modules/s3"
  bucket_name = "${var.application}-documents"
}

# =============================================================================
# ECR — Docker image repository
# =============================================================================
module "ecr" {
  source          = "../../modules/ecr"
  repository_name = "nmd-genai-${var.candidate_name}-repo"
}

# =============================================================================
# Lambda — Processing functions
# =============================================================================
module "lambda" {
  source      = "../../modules/lambda"
  application = var.application
  environment = var.environment

  ecr_image_uri    = "${module.ecr.repository_url}:latest"
  s3_bucket_arn    = module.s3.bucket_arn
  s3_bucket_name   = module.s3.bucket_name
  bedrock_model_id = var.bedrock_model_id
  log_level        = var.log_level
}

# =============================================================================
# Step Functions — Pipeline
# =============================================================================
module "step_functions" {
  source      = "../../modules/step-functions"
  application = var.application
  environment = var.environment
  name        = "pipeline"
  aws_region  = var.aws_region

  preprocess_lambda_arn = module.lambda.preprocess_arn
  classify_lambda_arn   = module.lambda.classify_arn
  extract_lambda_arn    = module.lambda.extract_arn
  aggregate_lambda_arn  = module.lambda.aggregate_arn
}

# =============================================================================
# EventBridge — S3 upload trigger
# =============================================================================
module "eventbridge" {
  source      = "../../modules/eventbridge"
  application = var.application
  environment = var.environment
  name        = "s3-upload"

  source_bucket_name = module.s3.bucket_name
  source_bucket_arn  = module.s3.bucket_arn
  state_machine_arn  = module.step_functions.state_machine_arn
}
