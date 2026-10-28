resource "aws_iam_role" "sfn" {
  name = "${var.application}-${var.environment}-sfn-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_invoke" {
  name = "invoke-lambdas"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          var.preprocess_lambda_arn,
          var.classify_lambda_arn,
          var.extract_lambda_arn,
          var.aggregate_lambda_arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
        ]
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/states/${var.application}-${var.environment}-${var.name}"
  retention_in_days = 30
}

resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.application}-${var.environment}-${var.name}"
  type     = "STANDARD"
  role_arn = aws_iam_role.sfn.arn

  definition = templatefile("${path.module}/state_machine.asl.json", {
    preprocess_arn = var.preprocess_lambda_arn
    classify_arn   = var.classify_lambda_arn
    extract_arn    = var.extract_lambda_arn
    aggregate_arn  = var.aggregate_lambda_arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = false
    level                  = "ERROR"
  }

  tags = { Name = "${var.application}-${var.environment}-${var.name}" }
}
