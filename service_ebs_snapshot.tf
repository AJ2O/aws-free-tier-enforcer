variable "lambda_name_ebs_snapshot" {
  default = "FFT_EBS-Snapshot"
}

# Lambda Execution Role
resource "aws_iam_role" "ebs_snapshot_lambda" {
  name               = "${var.lambda_name_ebs_snapshot}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "ebs_snapshot_lambda" {
  name        = "${var.lambda_name_ebs_snapshot}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_ebs_snapshot}."
  policy      = file("IAM/ebs_snapshot.json")
}

resource "aws_iam_role_policy_attachment" "ebs_snapshot_lambda_attach1" {
  role       = aws_iam_role.ebs_snapshot_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "ebs_snapshot_lambda_attach2" {
  role       = aws_iam_role.ebs_snapshot_lambda.name
  policy_arn = aws_iam_policy.ebs_snapshot_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ebs_snapshot_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_ebs_snapshot}"
}

# Lambda Function for EBS-Snapshot Free-Tier
resource "aws_lambda_function" "ebs_snapshot" {
  function_name = var.lambda_name_ebs_snapshot
  role          = aws_iam_role.ebs_snapshot_lambda.arn

  filename = "Lambda/ebs_snapshot.zip"
  handler  = "ebs_snapshot.handler"
  runtime  = "nodejs12.x"

  timeout = 60

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.ebs_snapshot_lambda_logs,
    aws_iam_role_policy_attachment.ebs_snapshot_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "ebs_snapshot" {
  name          = var.lambda_name_ebs_snapshot
  description   = "Triggers on pending EBS snapshots"
  event_pattern = file("EventBridge_Patterns/ebs_snapshot.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "ebs_snapshot" {
  rule = aws_cloudwatch_event_rule.ebs_snapshot.name
  arn  = aws_lambda_function.ebs_snapshot.arn

  input_path = "$.detail.responseElements"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "ebs_snapshot" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_snapshot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_snapshot.arn
}