//Declare Variables
variable "aws_region" {}

variable "al_api_endpoint" {}

variable "aws_account_id" {}

variable "aims_access_key_id" {}

variable "aims_secret_key" {}

variable "kinesis_name" {}

variable "kms_policy" {}

variable "kms_alias" {}

variable "guard_duty_s3_bucket" {}

variable "guard_duty_s3_key" {}

variable "lambda_config_name" {}

variable "lambda_function_name" {}

variable "update_schedule_event" {}

variable "checkin_scheduled_event" {}

variable "cloud_watch_event_rule_name" {}

variable "collect_lambda_role_name" {}

variable "encrypt_lambda_role_name" {}

variable "cw_event_role_name" {}

variable "lambda_health_check_policy" {}

variable "encrypt_lambda_policy" {}

variable "guard_duty_lambda_policy" {}

variable "cloud_watch_event_policy" {}

variable "kms_key_policy" {}

variable "encrypt_kms_policy" {}
