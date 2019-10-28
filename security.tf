//Health Check Lambda Policy
resource "aws_iam_policy" "health_check_lambda_policy" {
  name = "alertlogic-health-check-lambda-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": [
       "events:DescribeRule",
       "events:ListTargetsByRule"
       ],
    "Resource": "${aws_cloudwatch_event_rule.guard_duty_cloudwatch_event_rule.arn}"
   },
  {
    "Effect": "Allow",
    "Action": [
       "cloudwatch:Get*",
       "cloudwatch:Describe*",
       "cloudwatch:List*"
       ],
    "Resource": "*"
   }
  ]
 }
EOF
}

//Create Encrypt Lambda Policy - REMEMBER TO ATTACH TO ENCRYPT LAMBA ROLE(Done)
resource "aws_iam_policy" "encrypt_lambda_policy" {
  name = "alertlogic-encrypt-lambda-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": "logs:CreateLogGroup",
    "Resource": "arn:aws:logs:us-east-1:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.encrypt_lambda_function.name:*"
   },
  {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "arn:aws:logs:us-east-1:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.encrypt_lambda_function.name:log-stream:log-stream:*"
   }
 ]
}
EOF
}

//Create Collect Lambda Policy - REMEMBER TO ATTACH TO COLLECT LAMBA ROLE(Done)
resource "aws_iam_policy" "collect_lambda_policy" {
  name = "alertlogic-guardduty-lambda-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": "logs:CreateLogGroup",
    "Resource": "arn:aws:logs:us-east-1:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.collect_lambda_function.name:*"
   },
  {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "arn:aws:logs:us-east-1:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.collect_lambda_function.name:log-stream:log-stream:*"
   },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:*"
    ],
    "Resource": "${aws_lambda_function.encrypt_lambda_function.arn}"
   },
  {
    "Effect": "Allow",
    "Action": [
      "KinesisStream:*"
    ],
    "Resource": "${aws_kinesis_stream.al_cwe_collector.arn}"
   },
  {
    "Effect": "Allow",
    "Action": [
      "S3:Get*"
    ],
    "Resource": "arn:aws:s3:::alertlogic-collectors-us-east-1/*"
   }
 ]
}
EOF
}

//Create Cloud Watch Event Policy - REMEMBER TO ATTACH TO ENCRYPT LAMBA ROLE(Done)
resource "aws_iam_policy" "cloud_watch_event_policy" {
  name = "alertlogic-cloudwatch-event-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream"
      ],
    "Resource": "${aws_kinesis_stream.al_cwe_collector.arn}"
   },
  {
    "Effect": "Allow",
    "Action": [
      "kinesis:ListStreams"
    ],
    "Resource": "*"
   },
   {
    "Effect": "Allow",
    "Action": [
      "lambda:*"
    ],
    "Resource": "${aws_lambda_function.collect_lambda_function.arn}"
   }
 ]
}
EOF
}

// Attach Encrypted IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "encrypt_lambda_policy_attachment" {
  role       = "${aws_iam_role.encrypt_lambda_role.name}"
  policy_arn = "${aws_iam_policy.encrypt_lambda_policy.arn}"
}

// Attach Health Check Lambda IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "health_check_lambda_policy_attachment" {
  role       = "${aws_iam_role.collect_lambda_role.name}"
  policy_arn = "${aws_iam_policy.health_check_lambda_policy.arn}"
}

// Attach Collected IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "collect_lambda_policy_attachment" {
  role       = "${aws_iam_role.collect_lambda_role.name}"
  policy_arn = "${aws_iam_policy.collect_lambda_policy.arn}"
}

// Attach Cloud Watch Event IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "cloud_watch_event_policy_attachment" {
  role       = "${aws_iam_role.cloud_watch_event_role.name}"
  policy_arn = "${aws_iam_policy.cloud_watch_event_policy.arn}"
}
