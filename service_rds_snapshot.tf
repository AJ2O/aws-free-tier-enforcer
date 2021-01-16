variable "lambda_name_rds_snapshot" {
  default = "FFT_RDS-Snapshot"
}

# Lambda Execution Role
resource "aws_iam_role" "rds_snapshot_lambda" {
  name               = "${var.lambda_name_rds_snapshot}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "rds_snapshot_lambda" {
  name        = "${var.lambda_name_rds_snapshot}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_rds_snapshot}."
  policy      = file("IAM/rds_snapshot.json")
}

resource "aws_iam_role_policy_attachment" "rds_snapshot_lambda_attach1" {
  role       = aws_iam_role.rds_snapshot_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "rds_snapshot_lambda_attach2" {
  role       = aws_iam_role.rds_snapshot_lambda.name
  policy_arn = aws_iam_policy.rds_snapshot_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "rds_snapshot_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_rds_snapshot}"
}

# Lambda Function for RDS Snapshot Free-Tier
resource "aws_lambda_function" "rds_snapshot" {
  function_name = var.lambda_name_rds_snapshot
  role          = aws_iam_role.rds_snapshot_lambda.arn

  filename = "Lambda/rds_snapshot.zip"
  handler  = "rds_snapshot.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.rds_snapshot_lambda_logs,
    aws_iam_role_policy_attachment.rds_snapshot_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "rds_snapshot" {
  name          = var.lambda_name_rds_snapshot
  description   = "Triggers on pending RDS snapshots"
  event_pattern = file("EventBridge_Patterns/rds_snapshot.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "rds_snapshot" {
  rule = aws_cloudwatch_event_rule.rds_snapshot.name
  arn  = aws_lambda_function.rds_snapshot.arn

  input_path = "$.detail"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "rds_snapshot" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_snapshot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_snapshot.arn
}