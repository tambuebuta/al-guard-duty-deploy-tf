// Specify the provider and alternative access details below if needed
provider "aws" {
  profile                 = "default"
  shared_credentials_file = "~/.aws/credentials"
  region                  = "us-east-1"
  version                 = ">= 1.6"
}

data "aws_caller_identity" "current" {}

//Create Alert Logic Kinesis Stream
resource "aws_kinesis_stream" "al_cwe_collector" {
  name        = "al_kinesis_stream_name"
  shard_count = 1

  tags = {
    Name       = "AlertLogic CWE collector"
    AlertLogic = "Collect"
  }
}

//Create Basic Lambda Role
resource "aws_iam_role" "basic_lambda_role" {
  name = "al_basic_lambda_role_name"
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
  name = "al_collect_lambda_role_name"
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
  name = "al_encrypt_lambda_role_name"
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
  name = "cloud_watch_event_role_name"
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

//Create Lambda KMS Key
resource "aws_kms_key" "al_lambda_kms_key" {
  description = "kms key used to encrypt credentials for lambda"
  depends_on  = ["aws_iam_role.collect_lambda_role", "aws_iam_role.encrypt_lambda_role"]

  tags = {
    Name       = "AlertLogic CWE collector"
    AlertLogic = "Collect"
  }
}

//Create Lambda KMS Key alias
resource "aws_kms_alias" "al_kms_key_alias" {
  name          = "alias/guard-duty-key"
  target_key_id = "${aws_kms_key.al_lambda_kms_key.key_id}"
}

//Collect Lambda Function - Alert Logic Lambda Guard Duty event collector
resource "aws_lambda_function" "collect_lambda_function" {
  function_name = "al-cwe-collector"
  role          = "${aws_iam_role.collect_lambda_role.arn}"
  kms_key_arn   = "${aws_kms_key.al_lambda_kms_key.arn}"
  s3_bucket     = "alertlogic-collectors-us-east-1"
  s3_key        = "packages/lambda/al-cwe-collector.zip"
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  memory_size   = "128"
  timeout       = "300"

  environment {
    variables = {
      aims_access_key_id            = "${var.aims_access_key_id}"
      aims_secret_key               = "${var.aims_secret_key}"
      aws_lambda_s3_bucket          = "alertlogic-collectors-us-east-1"
      aws_lambda_zipfile_name       = "packages/lambda/al-cwe-collector.zip"
      aws_lambda_update_config_name = "configs/lambda/al-cwe-collector.json"
      al_api                        = "api.global-services.global.alertlogic.com"
      al_data_residency             = "default"
    }
  }

  tags = [
    {
      name = "AlertLogic CWE collector"
    },
    {
      AlertLogic = "Collect"
    },
  ]
}

//Archive Lambda Project in Zip File
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.js"
  output_path = "payload.zip"
}

//Encrypt Lambda Function
resource "aws_lambda_function" "encrypt_lambda_function" {
  filename         = "payload.zip"
  function_name    = "lamba_function_name"
  role             = "${aws_iam_role.encrypt_lambda_role.arn}"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  memory_size      = "128"
  timeout          = "5"

  tags = [
    {
      name = "AlertLogic CWE collector"
    },
    {
      AlertLogic = "Collect"
    },
  ]
}

//Create Update Scheduled Rule
resource "aws_cloudwatch_event_rule" "update_scheduled_rule" {
  name                = "update-scheduled-event-rule"
  role_arn            = "${aws_iam_role.cloud_watch_event_role.arn}"
  description         = "Scheduled rule for updater function"
  schedule_expression = "rate(12 hours)"
  is_enabled          = "true"
}

//Create Update Scheduled Rule Lambda Invoke Permission
resource "aws_lambda_permission" "allow_update_schedule_rule" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.collect_lambda_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.update_scheduled_rule.arn}"
}

//Create Cloud Watch Event Target resource for Update Schedule Rule
resource "aws_cloudwatch_event_target" "update_scheduled_target" {
  rule      = "${aws_cloudwatch_event_rule.update_scheduled_rule.name}"
  target_id = "1"
  arn       = "${aws_kinesis_stream.al_cwe_collector.arn}"
  input     = "{\"RequestType\": \"ScheduledEvent\", \"Type\": \"SelfUpdate\"}"
}

//Create Checkin Scheduled Rule
resource "aws_cloudwatch_event_rule" "checkin_scheduled_rule" {
  name                = "checkin-scheduled-rule"
  role_arn            = "${aws_iam_role.cloud_watch_event_role.arn}"
  description         = "Scheduled rule for checkin function"
  schedule_expression = "rate(15 minutes)"
  is_enabled          = "true"
}

//Create Checkin Scheduled Rule Lambda Invoke Permission
resource "aws_lambda_permission" "allow_checkin_schedule_rule" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.collect_lambda_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.checkin_scheduled_rule.arn}"
}

//Create Guard Duty Cloudwatch Event Rule
resource "aws_cloudwatch_event_rule" "guard_duty_cloudwatch_event_rule" {
  name                = "alert-logic-guard-duty-event-rule"
  role_arn            = "${aws_iam_role.cloud_watch_event_role.arn}"
  description         = "CloudWatch events rule for Guard Duty events"
  schedule_expression = ""
  is_enabled          = "true"

  event_pattern = <<PATTERN
  {
    "detail-type": [
      "GuardDuty Finding"
     ],
    "source":[
      "aws.guarduty"
    ]
  }
PATTERN
}

//Create Cloud Watch Event Target resource for Guard Duty
resource "aws_cloudwatch_event_target" "guard_duty_target" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_cloudwatch_event_rule.name}"
  target_id = "1"
  arn       = "${aws_kinesis_stream.al_cwe_collector.arn}"
}

//Create Cloud Watch Event Target resource for Update Schedule Rule
resource "aws_cloudwatch_event_target" "checkin_scheduled_target" {
  rule      = "${aws_cloudwatch_event_rule.checkin_scheduled_rule.name}"
  target_id = "1"
  arn       = "${aws_lambda_function.collect_lambda_function.arn}"
  input     = "{\"RequestType\": \"ScheduledEvent\",\"Type\": \"Checkin\", \"AwsAccountId\": \"989608343549\", \"Region\": \"us-east-1\", \"KinesisArn\": \"${aws_kinesis_stream.al_cwe_collector.arn}\", \"CloudWatchEventsRule\": \"${aws_cloudwatch_event_rule.guard_duty_cloudwatch_event_rule.name}\", \"CweRulePattern\": \"{\\\"detail-type\\\":[\\\"GuardDuty Finding\\\"],\\\"source\\\":[\\\"aws.guardduty\\\"]}\"}"
}
