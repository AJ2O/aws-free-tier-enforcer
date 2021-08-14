variable "lambda_name_dynamodb" {
  default = "FFT_DynamoDB"
}

# Lambda Execution Role
resource "aws_iam_role" "dynamodb_lambda" {
  name               = "${var.lambda_name_dynamodb}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "dynamodb_lambda" {
  name        = "${var.lambda_name_dynamodb}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_dynamodb}."
  policy      = file("IAM/dynamodb.json")
}

resource "aws_iam_role_policy_attachment" "dynamodb_lambda_attach1" {
  role       = aws_iam_role.dynamodb_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_lambda_attach2" {
  role       = aws_iam_role.dynamodb_lambda.name
  policy_arn = aws_iam_policy.dynamodb_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "dynamodb_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_dynamodb}"
}

# Lambda Function for DynamoDB Free-Tier
resource "aws_lambda_function" "dynamodb" {
  function_name = var.lambda_name_dynamodb
  role          = aws_iam_role.dynamodb_lambda.arn

  filename = "Lambda/dynamodb.zip"
  handler  = "dynamodb.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.dynamodb_lambda_logs,
    aws_iam_role_policy_attachment.dynamodb_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "dynamodb" {
  name          = var.lambda_name_dynamodb
  description   = "Triggers on pending DynamoDB instances"
  event_pattern = file("EventBridge_Patterns/dynamodb.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "dynamodb" {
  rule = aws_cloudwatch_event_rule.dynamodb.name
  arn  = aws_lambda_function.dynamodb.arn

  input_path = "$.detail.responseElements"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "dynamodb" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamodb.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dynamodb.arn
}