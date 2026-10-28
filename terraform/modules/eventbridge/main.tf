resource "aws_iam_role" "eventbridge" {
  name = "${var.application}-${var.environment}-eb-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_sfn" {
  name = "start-step-functions"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = [var.state_machine_arn]
    }]
  })
}

resource "aws_cloudwatch_event_rule" "s3_upload" {
  name        = "${var.application}-${var.environment}-${var.name}"
  description = "Trigger pipeline on S3 upload"
  tags        = { Name = "${var.application}-${var.environment}-${var.name}" }

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [var.source_bucket_name] }
      object = { key = [{ prefix = "uploads/" }] }
    }
  })
}

resource "aws_cloudwatch_event_target" "sfn" {
  rule     = aws_cloudwatch_event_rule.s3_upload.name
  arn      = var.state_machine_arn
  role_arn = aws_iam_role.eventbridge.arn

  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name"
      key    = "$.detail.object.key"
    }
    input_template = <<-EOF
      {"s3_bucket": <bucket>, "s3_key": <key>}
    EOF
  }
}
