resource "aws_s3_bucket" "documents" {
  bucket = var.bucket_name

  lifecycle {
    precondition {
      condition     = startswith(var.bucket_name, "nmd-genai-")
      error_message = "S3 bucket name must start with 'nmd-genai-' to match IAM policy scoping."
    }
  }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "eventbridge" {
  bucket      = aws_s3_bucket.documents.id
  eventbridge = true
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
