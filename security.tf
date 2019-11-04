//Create Basic Lambda Role
resource "aws_iam_role" "basic_lambda_role" {
  name = "${var.basic_lambda_role}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

//Create Collect Lambda IAM Role
resource "aws_iam_role" "collect_lambda_role" {
  name = "${var.collect_lambda_role_name}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
}
EOF
}

//Create Encrypt Lambda Role
resource "aws_iam_role" "encrypt_lambda_role" {
  name = "${var.encrypt_lambda_role_name}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

//Cloud Watch Event Role
resource "aws_iam_role" "cloud_watch_event_role" {
  name = "${var.cw_event_role_name}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

//Health Check Lambda Policy
resource "aws_iam_policy" "health_check_lambda_policy" {
  name = "${var.lambda_health_check_policy}"
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
  name = "${var.encrypt_lambda_policy}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": "logs:CreateLogGroup",
    "Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.encrypt_lambda_function.name:*"
   },
  {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.encrypt_lambda_function.name:log-stream:log-stream:*"
   }
 ]
}
EOF
}

//Create Collect Lambda Policy - REMEMBER TO ATTACH TO COLLECT LAMBA ROLE(Done)
resource "aws_iam_policy" "collect_lambda_policy" {
  name = "${var.guard_duty_lambda_policy}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": "logs:CreateLogGroup",
    "Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.collect_lambda_function.name:*"
   },
  {
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "arn:aws:logs:${var.aws_region}:${var.aws_account_id}::log-group:/aws/lambda/aws_lambda_function.collect_lambda_function.name:log-stream:log-stream:*"
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
    "Resource": "arn:aws:s3:::${var.guard_duty_s3_bucket}/*"
   }
 ]
}
EOF
}

//Create Cloud Watch Event Policy - REMEMBER TO ATTACH TO ENCRYPT LAMBA ROLE(Done)
resource "aws_iam_policy" "cloud_watch_event_policy" {
  name = "${var.cloud_watch_event_policy}"
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

//KMS Key Policy
resource "aws_iam_policy" "collect_kms_key_policy" {
  name = "${var.kms_key_policy}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:encrypt"
      ],
      "Resource": "*"
    }
}
EOF
}


//Encrypt KMS Key Policy
resource "aws_iam_policy" "encrypt_kms_key_policy" {
  name = "${var.encrypt_kms_policy}"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
      "Effect": "Allow",
      "Action": [
        "kms:encrypt"
      ],
      "Resource": "*"
    }
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

// Attach Collected IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "collect_lambda_kms_policy_attachment" {
  role       = "${aws_iam_role.collect_lambda_role.name}"
  policy_arn = "${aws_iam_policy.collect_kms_key_policy.arn}"
}

// Attach Encrypted IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "encrypt_lambda_kms_policy_attachment" {
  role       = "${aws_iam_role.encrypt_lambda_role.name}"
  policy_arn = "${aws_iam_policy.encrypt_kms_key_policy.arn}"
}
