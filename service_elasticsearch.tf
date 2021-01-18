variable "lambda_name_elasticsearch" {
  default = "FFT_Elasticsearch"
}

# Lambda Execution Role
resource "aws_iam_role" "elasticsearch_lambda" {
  name               = "${var.lambda_name_elasticsearch}-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fft_tags
}

resource "aws_iam_policy" "elasticsearch_lambda" {
  name        = "${var.lambda_name_elasticsearch}-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_elasticsearch}."
  policy      = file("IAM/elasticsearch.json")
}

resource "aws_iam_role_policy_attachment" "elasticsearch_lambda_attach1" {
  role       = aws_iam_role.elasticsearch_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "elasticsearch_lambda_attach2" {
  role       = aws_iam_role.elasticsearch_lambda.name
  policy_arn = aws_iam_policy.elasticsearch_lambda.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "elasticsearch_lambda_logs" {
  name = "/aws/lambda/${var.lambda_name_elasticsearch}"
}

# Lambda Function for Elasticsearch Free-Tier
resource "aws_lambda_function" "elasticsearch" {
  function_name = var.lambda_name_elasticsearch
  role          = aws_iam_role.elasticsearch_lambda.arn

  filename = "Lambda/elasticsearch.zip"
  handler  = "elasticsearch.handler"
  runtime  = "nodejs12.x"

  tags = var.fft_tags

  depends_on = [
    aws_cloudwatch_log_group.elasticsearch_lambda_logs,
    aws_iam_role_policy_attachment.elasticsearch_lambda_attach2
  ]
}

# EventBridge Configuration
resource "aws_cloudwatch_event_rule" "elasticsearch" {
  name          = var.lambda_name_elasticsearch
  description   = "Triggers on pending Elasticsearch clusters"
  event_pattern = file("EventBridge_Patterns/elasticsearch.json")
  tags          = var.fft_tags
}

resource "aws_cloudwatch_event_target" "elasticsearch" {
  rule = aws_cloudwatch_event_rule.elasticsearch.name
  arn  = aws_lambda_function.elasticsearch.arn

  input_path = "$.detail.responseElements.domainStatus"
}

# Invoke Lambda via EventBridge
resource "aws_lambda_permission" "elasticsearch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.elasticsearch.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.elasticsearch.arn
}