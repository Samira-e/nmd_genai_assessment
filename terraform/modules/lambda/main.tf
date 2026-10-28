resource "aws_iam_role" "lambda" {
  name = "${var.application}-${var.environment}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_access" {
  name = "lambda-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = ["arn:aws:bedrock:*::foundation-model/*", "arn:aws:bedrock:*:*:inference-profile/*"]
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "preprocess" {
  name              = "/aws/lambda/${var.application}-${var.environment}-preprocess"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "classify" {
  name              = "/aws/lambda/${var.application}-${var.environment}-classify"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "extract" {
  name              = "/aws/lambda/${var.application}-${var.environment}-extract"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "aggregate" {
  name              = "/aws/lambda/${var.application}-${var.environment}-aggregate"
  retention_in_days = 30
}

resource "aws_lambda_function" "preprocess" {
  function_name = "${var.application}-${var.environment}-preprocess"
  package_type  = "Image"
  image_uri     = var.ecr_image_uri
  architectures = ["arm64"]
  timeout       = 60
  memory_size   = 256
  role          = aws_iam_role.lambda.arn

  image_config {
    command = ["lambdas.preprocess.handler.handler"]
  }

  environment {
    variables = {
      LOG_LEVEL      = var.log_level
      S3_BUCKET_NAME = var.s3_bucket_name
    }
  }

  lifecycle {
    precondition {
      condition     = 256 <= var.max_lambda_memory_mb
      error_message = "Preprocess memory (256 MB) exceeds the allowed maximum."
    }
  }

  tags = { Name = "${var.application}-${var.environment}-preprocess" }
}

resource "aws_lambda_function" "classify" {
  function_name = "${var.application}-${var.environment}-classify"
  package_type  = "Image"
  image_uri     = var.ecr_image_uri
  architectures = ["arm64"]
  timeout       = 120
  memory_size   = 512
  role          = aws_iam_role.lambda.arn

  image_config {
    command = ["lambdas.classify.handler.handler"]
  }

  environment {
    variables = {
      LOG_LEVEL        = var.log_level
      S3_BUCKET_NAME   = var.s3_bucket_name
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  lifecycle {
    precondition {
      condition     = 512 <= var.max_lambda_memory_mb
      error_message = "Classify memory (512 MB) exceeds the allowed maximum."
    }
  }

  tags = { Name = "${var.application}-${var.environment}-classify" }
}

resource "aws_lambda_function" "extract" {
  function_name = "${var.application}-${var.environment}-extract"
  package_type  = "Image"
  image_uri     = var.ecr_image_uri
  architectures = ["arm64"]
  timeout       = 300
  memory_size   = 1024
  role          = aws_iam_role.lambda.arn

  image_config {
    command = ["lambdas.extract.handler.handler"]
  }

  environment {
    variables = {
      LOG_LEVEL        = var.log_level
      S3_BUCKET_NAME   = var.s3_bucket_name
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  lifecycle {
    precondition {
      condition     = 1024 <= var.max_lambda_memory_mb
      error_message = "Extract memory (1024 MB) exceeds the allowed maximum."
    }
    precondition {
      condition     = 300 <= var.max_lambda_timeout_seconds
      error_message = "Extract timeout (300s) exceeds the allowed maximum."
    }
  }

  tags = { Name = "${var.application}-${var.environment}-extract" }
}

resource "aws_lambda_function" "aggregate" {
  function_name = "${var.application}-${var.environment}-aggregate"
  package_type  = "Image"
  image_uri     = var.ecr_image_uri
  architectures = ["arm64"]
  timeout       = 120
  memory_size   = 512
  role          = aws_iam_role.lambda.arn

  image_config {
    command = ["lambdas.aggregate.handler.handler"]
  }

  environment {
    variables = {
      LOG_LEVEL      = var.log_level
      S3_BUCKET_NAME = var.s3_bucket_name
    }
  }

  lifecycle {
    precondition {
      condition     = 512 <= var.max_lambda_memory_mb
      error_message = "Aggregate memory (512 MB) exceeds the allowed maximum."
    }
  }

  tags = { Name = "${var.application}-${var.environment}-aggregate" }
}
