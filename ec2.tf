variable "lambda_name_ec2" {
  default = "FFT_EC2"
}

# Lambda Execution Role
resource "aws_iam_role" "ec2_lambda" {
  name               = "${var.lambda_name_ec2}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "ec2_lambda" {
  name        = "${var.lambda_name_ec2}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_ec2}."
  policy      = file("IAM/ec2.json")
}

resource "aws_iam_role_policy_attachment" "ec2_lambda_attach1" {
  role       = aws_iam_role.ec2_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "ec2_lambda_attach2" {
  role       = aws_iam_role.ec2_lambda.name
  policy_arn = aws_iam_policy.ec2_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ec2_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_ec2}"
}

# Lambda Function for EC2 Free-Tier
resource "aws_lambda_function" "ec2" {
  function_name = var.lambda_name_ec2
  role          = aws_iam_role.ec2_lambda.arn

  filename = "Lambda/ec2.zip"
  handler  = "ec2.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.ec2_lambda_logs,
    aws_iam_role_policy_attachment.ec2_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "ec2" {
  name        = var.lambda_name_ec2
  description = "Triggers on pending EC2 instances"
  event_pattern = file("EventBridge_Patterns/ec2.json")
  tags = var.fft_tags
}

resource "aws_cloudwatch_event_target" "ec2" {
  rule = aws_cloudwatch_event_rule.ec2.name
  arn  = aws_lambda_function.ec2.arn

  input_path = "$.detail"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "ec2" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2.arn
}