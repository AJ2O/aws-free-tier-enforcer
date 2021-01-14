variable "lambda_name_rds" {
  default = "FFT_RDS"
}

# Lambda Execution Role
resource "aws_iam_role" "rds_lambda" {
  name               = "${var.lambda_name_rds}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "rds_lambda" {
  name        = "${var.lambda_name_rds}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_rds}."
  policy      = file("IAM/rds.json")
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attach1" {
  role       = aws_iam_role.rds_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attach2" {
  role       = aws_iam_role.rds_lambda.name
  policy_arn = aws_iam_policy.rds_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "rds_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_rds}"
}

# Lambda Function for RDS Free-Tier
resource "aws_lambda_function" "rds" {
  function_name = var.lambda_name_rds
  role          = aws_iam_role.rds_lambda.arn

  filename = "Lambda/rds.zip"
  handler  = "rds.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.rds_lambda_logs,
    aws_iam_role_policy_attachment.rds_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "rds" {
  name          = var.lambda_name_rds
  description   = "Triggers on pending RDS instances"
  event_pattern = file("EventBridge_Patterns/rds.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "rds" {
  rule = aws_cloudwatch_event_rule.rds.name
  arn  = aws_lambda_function.rds.arn

  input_path = "$.detail"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "rds" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds.arn
}