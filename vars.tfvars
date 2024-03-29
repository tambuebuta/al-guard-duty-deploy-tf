aws_region = "xx-xxxx-x"
aws_account_id = "xxxxxx"
aims_secret_key = "xxxxxx"
aims_access_key_id = "xxxx"
al_api_endpoint = "api.global-services.global.alertlogic.com"
kinesis_name = "guard-duty-kinesis"
kms_policy = "kms-policy.json"
kms_alias = "alias/guard-duty-key-01"
guard_duty_s3_bucket = "al-collectors-us-east-1"
guard_duty_s3_key = "packages/lambda/al-cwe-collector.zip"
lambda_config_name =  "configs/lambda/al-cwe-collector.json"
lambda_function_name = "encrypt-lambda-function"
update_schedule_event = "update-scheduled-event-rule"
checkin_scheduled_event  = "checkin-scheduled-rule"
cloud_watch_event_rule_name  = "alert-logic-guard-duty-event-rule"
collect_lambda_role_name = "al-collect-lambda"
encrypt_lambda_role_name = "al-encrypt-lambda"
cw_event_role_name = "cloud-watch-event"
lambda_health_check_policy =  "al-health-check-lambda-policy"
encrypt_lambda_policy = "al-encrypt-lambda-policy"
guard_duty_lambda_policy = "al-guardduty-lambda-policy"
cloud_watch_event_policy = "al-cloudwatch-event-policy"
kms_key_policy = "al-kms-key-policy"
encrypt_kms_policy  = "encrypt-kms-key-policy"
basic_lambda_role = "gd-basic-lambda-role"
collect_fxn_name = "al-collector"
