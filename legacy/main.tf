# Lambda Execution Role
resource "aws_iam_role" "fte_lambda" {
  name               = "FreeTierEnforcer-ExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.shared_lambda_assume_role.json

  tags = var.fte_tags
}

resource "aws_iam_policy" "fte_lambda" {
  name        = "FreeTierEnforcer-Policy"
  path        = "/"
  description = "IAM Policy for Lambda function ${var.lambda_name_ec2}."
  policy      = file("IAM/ec2.json")
}

resource "aws_iam_role_policy_attachment" "fte_lambda_attach1" {
  role       = aws_iam_role.fte_lambda.name
  policy_arn = aws_iam_policy.shared_lambda.arn
}

resource "aws_iam_role_policy_attachment" "ec2_lambda_attach2" {
  role       = aws_iam_role.ec2_lambda.name
  policy_arn = aws_iam_policy.ec2_lambda.arn
}