variable "lambda_name_elasticache" {
  default = "FFT_ElastiCache"
}

# Lambda Execution Role
resource "aws_iam_role" "elasticache_lambda" {
  name               = "${var.lambda_name_elasticache}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "elasticache_lambda" {
  name        = "${var.lambda_name_elasticache}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_elasticache}."
  policy      = file("IAM/elasticache.json")
}

resource "aws_iam_role_policy_attachment" "elasticache_lambda_attach1" {
  role       = aws_iam_role.elasticache_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "elasticache_lambda_attach2" {
  role       = aws_iam_role.elasticache_lambda.name
  policy_arn = aws_iam_policy.elasticache_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "elasticache_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_elasticache}"
}

# Lambda Function for ElastiCache Free-Tier
resource "aws_lambda_function" "elasticache" {
  function_name = var.lambda_name_elasticache
  role          = aws_iam_role.elasticache_lambda.arn

  filename = "Lambda/elasticache.zip"
  handler  = "elasticache.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.elasticache_lambda_logs,
    aws_iam_role_policy_attachment.elasticache_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "elasticache" {
  name          = var.lambda_name_elasticache
  description   = "Triggers on pending ElastiCache instances"
  event_pattern = file("EventBridge_Patterns/elasticache.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "elasticache" {
  rule = aws_cloudwatch_event_rule.elasticache.name
  arn  = aws_lambda_function.elasticache.arn

  input_path = "$.detail.responseElements"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "elasticache" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.elasticache.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.elasticache.arn
}