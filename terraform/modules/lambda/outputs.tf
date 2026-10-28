output "preprocess_arn" { value = aws_lambda_function.preprocess.arn }
output "classify_arn" { value = aws_lambda_function.classify.arn }
output "extract_arn" { value = aws_lambda_function.extract.arn }
output "aggregate_arn" { value = aws_lambda_function.aggregate.arn }
