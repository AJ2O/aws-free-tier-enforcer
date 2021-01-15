variable "lambda_name_ebs" {
  default = "FFT_EBS"
}

# Lambda Execution Role
resource "aws_iam_role" "ebs_lambda" {
  name               = "${var.lambda_name_ebs}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "ebs_lambda" {
  name        = "${var.lambda_name_ebs}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_ebs}."
  policy      = file("IAM/ebs.json")
}

resource "aws_iam_role_policy_attachment" "ebs_lambda_attach1" {
  role       = aws_iam_role.ebs_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "ebs_lambda_attach2" {
  role       = aws_iam_role.ebs_lambda.name
  policy_arn = aws_iam_policy.ebs_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ebs_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_ebs}"
}

# Lambda Function for EBS Free-Tier
resource "aws_lambda_function" "ebs" {
  function_name = var.lambda_name_ebs
  role          = aws_iam_role.ebs_lambda.arn

  filename = "Lambda/ebs.zip"
  handler  = "ebs.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.ebs_lambda_logs,
    aws_iam_role_policy_attachment.ebs_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "ebs" {
  name          = var.lambda_name_ebs
  description   = "Triggers on pending EBS instances"
  event_pattern = file("EventBridge_Patterns/ebs.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "ebs" {
  rule = aws_cloudwatch_event_rule.ebs.name
  arn  = aws_lambda_function.ebs.arn

  input_path = "$.detail.responseElements"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "ebs" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs.arn
}