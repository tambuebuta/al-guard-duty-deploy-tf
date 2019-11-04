// Specify the provider and alternative access details below if needed
provider "aws" {
  profile                 = "default"
  shared_credentials_file = "~/.aws/credentials"
  region                  = "us-east-1"
  version                 = ">= 1.6"
}

provider "archive" {
  version = "~> 1.3"
}

data "aws_caller_identity" "current" {}

//Create Alert Logic Kinesis Stream
resource "aws_kinesis_stream" "al_cwe_collector" {
  name        = "${var.kinesis_name}"
  shard_count = 1

  tags = {
    Name       = "AlertLogic CWE collector"
    AlertLogic = "Collect"
  }
}

//Create Lambda KMS Key
resource "aws_kms_key" "al_lambda_kms_key" {
  description = "kms key used to encrypt credentials for lambda"
  policy      = "${file(var.kms_policy)}"
  depends_on  = ["aws_iam_role.collect_lambda_role", "aws_iam_role.encrypt_lambda_role"]

  tags = {
    Name       = "AlertLogic CWE collector"
    AlertLogic = "Collect"
  }
}

//Create Lambda KMS Key alias
resource "aws_kms_alias" "al_kms_key_alias" {
  name          = "${var.kms_alias}"
  target_key_id = "${aws_kms_key.al_lambda_kms_key.key_id}"
}

//Collect Lambda Function - Alert Logic Lambda Guard Duty event collector
resource "aws_lambda_function" "collect_lambda_function" {
  function_name = "${var.collect_fxn_name}"
  role          = "${aws_iam_role.collect_lambda_role.arn}"
  kms_key_arn   = "${aws_kms_key.al_lambda_kms_key.arn}"
  s3_bucket     = "${var.guard_duty_s3_bucket}"
  s3_key        = "${var.guard_duty_s3_key}"
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  memory_size   = "128"
  timeout       = "300"

  environment {
    variables = {
      aims_access_key_id            = "${var.aims_access_key_id}"
      aims_secret_key               = "${var.aims_secret_key}"
      aws_lambda_s3_bucket          = "${var.guard_duty_s3_bucket}"
      aws_lambda_zipfile_name       = "${var.guard_duty_s3_key}"
      aws_lambda_update_config_name = "${var.lambda_config_name}"
      al_api                        = "${var.al_api_endpoint}"
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
  function_name    = "${var.lambda_function_name}"
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
  name                = "${var.update_schedule_event}"
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
  name                = "${var.checkin_scheduled_event}"
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
  name                = "${var.cloud_watch_event_rule_name}"
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
  input     = "{\"RequestType\": \"ScheduledEvent\",\"Type\": \"Checkin\", \"AwsAccountId\": \"${var.aws_account_id}\", \"Region\": \"${var.aws_region}\", \"KinesisArn\": \"${aws_kinesis_stream.al_cwe_collector.arn}\", \"CloudWatchEventsRule\": \"${aws_cloudwatch_event_rule.guard_duty_cloudwatch_event_rule.name}\", \"CweRulePattern\": \"{\\\"detail-type\\\":[\\\"GuardDuty Finding\\\"],\\\"source\\\":[\\\"aws.guardduty\\\"]}\"}"
}
