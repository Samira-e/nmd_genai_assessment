variable "application" { type = string }
variable "environment" { type = string }
variable "name" { type = string }
variable "aws_region" { type = string }
variable "preprocess_lambda_arn" { type = string }
variable "classify_lambda_arn" { type = string }
variable "extract_lambda_arn" { type = string }
variable "aggregate_lambda_arn" { type = string }
