// IAM Policies
resource "aws_iam_policy" "shared_lambda" {
  name        = "${var.fft_prefix}-Policy"
  path        = "/"
  description = "IAM Policy for ${var.fft_prefix} Lambda functions."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}