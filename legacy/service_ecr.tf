variable "lambda_name_ecr" {
  default = "FFT_ECR"
}

# Lambda Execution Role
resource "aws_iam_role" "ecr_lambda" {
  name               = "${var.lambda_name_ecr}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "ecr_lambda" {
  name        = "${var.lambda_name_ecr}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_ecr}."
  policy      = file("IAM/ecr.json")
}

resource "aws_iam_role_policy_attachment" "ecr_lambda_attach1" {
  role       = aws_iam_role.ecr_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "ecr_lambda_attach2" {
  role       = aws_iam_role.ecr_lambda.name
  policy_arn = aws_iam_policy.ecr_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecr_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_ecr}"
}

# Lambda Function for ECR Free-Tier
resource "aws_lambda_function" "ecr" {
  function_name = var.lambda_name_ecr
  role          = aws_iam_role.ecr_lambda.arn

  filename = "Lambda/ecr.zip"
  handler  = "ecr.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.ecr_lambda_logs,
    aws_iam_role_policy_attachment.ecr_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "ecr" {
  name          = var.lambda_name_ecr
  description   = "Triggers on pending ECR instances"
  event_pattern = file("EventBridge_Patterns/ecr.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "ecr" {
  rule = aws_cloudwatch_event_rule.ecr.name
  arn  = aws_lambda_function.ecr.arn

  input_path = "$.detail"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "ecr" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecr.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr.arn
}