# ==============================================================================
# SQS TRIGGER LAMBDA -> STEP FUNCTION
# This Lambda receives messages from SQS and starts the Step Function workflow.
# ==============================================================================

# 1. Get SQS Queue ARN from the SAM stack
data "aws_cloudformation_stack" "sam_stack" {
  name = "earthquake-import-service"
}

# 2. Create the trigger Lambda using our module
module "notify_trigger_lambda" {
  source           = "./modules/lambda"
  function_name    = "NotifyTriggerHandler"
  source_code_path = "${path.module}/../check-lambdas/01-notify-trigger-handler"
  
  environment_variables = {
    STATE_MACHINE_ARN = aws_sfn_state_machine.notify_locations_workflow.id
  }
}

# 3. Define the policy to allow starting the Step Function
resource "aws_iam_policy" "start_sfn_policy" {
  name = "start-notify-workflow-policy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
        Action   = "states:StartExecution",
        Effect   = "Allow",
        Resource = [aws_sfn_state_machine.notify_locations_workflow.id]
    }]
  })
}

# 4. Attach the policy to the role created by the module
resource "aws_iam_role_policy_attachment" "notify_trigger_sfn_attachment" {
  role       = module.notify_trigger_lambda.role_name
  policy_arn = aws_iam_policy.start_sfn_policy.arn
}

# 5. Define the policy to allow reading from the SQS queue
resource "aws_iam_policy" "sqs_read_policy" {
  name = "sqs-trigger-read-policy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
        Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
        ],
        Effect   = "Allow",
        Resource = data.aws_cloudformation_stack.sam_stack.outputs["EarthquakeMetadataQueueArn"]
    }]
  })
}

# 6. Attach the SQS policy to the role
resource "aws_iam_role_policy_attachment" "notify_trigger_sqs_attachment" {
  role       = module.notify_trigger_lambda.role_name
  policy_arn = aws_iam_policy.sqs_read_policy.arn
}

# 7. Create the Event Source Mapping to link SQS and the trigger Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = data.aws_cloudformation_stack.sam_stack.outputs["EarthquakeMetadataQueueArn"]
  function_name    = module.notify_trigger_lambda.name
  batch_size       = 10
  enabled          = true
}