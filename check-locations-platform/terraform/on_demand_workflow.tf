# ==============================================================================
# ON-DEMAND CHECK WORKFLOW
# Triggered by the check-service API
# ==============================================================================

# 1. Lambda Function: On-Demand Check Handler
# ------------------------------------------------------------------------------

module "on_demand_check_lambda" {
  source           = "./modules/lambda"
  function_name    = "OnDemandCheckHandler"
  filename         = "${path.root}/../artifacts/OnDemandCheckHandler.zip"
  source_code_hash = filebase64sha256("${path.root}/../artifacts/OnDemandCheckHandler.zip")
  # This Lambda needs the name of the DynamoDB table to scan
  environment_variables = {
    DYNAMODB_TABLE_NAME = data.aws_cloudformation_stack.sam_stack.outputs["EarthquakeDataTableName"]
  }
}

# Attach the existing DynamoDB read policy to the new Lambda's role
resource "aws_iam_role_policy_attachment" "on_demand_dynamodb_attachment" {
  role       = module.on_demand_check_lambda.role_name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}


# 2. State Machine: On-Demand Check Workflow
# ------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "on_demand_check_workflow" {
  name     = "OnDemandCheckWorkflow"
  # We can reuse the same execution role as the other state machine
  role_arn = aws_iam_role.step_function_execution_role.arn

  definition = jsonencode({
    Comment = "A workflow to check a single user-provided location against all events.",
    StartAt = "CheckLocationAgainstAllEvents"
    States = {
      CheckLocationAgainstAllEvents = {
        Type       = "Task",
        Resource   = module.on_demand_check_lambda.arn,
        ResultPath = "$.CheckResult",
        Next       = "IsLocationAffected"
      },
      IsLocationAffected = {
        Type    = "Choice",
        Choices = [
          {
            Variable   = "$.CheckResult.isAffected",
            BooleanEquals = true,
            Next       = "NotifyOnDemand"
          }
        ],
        Default = "EndOnDemand"
      },
      NotifyOnDemand = {
        Type      = "Task",
        # Reusing the existing notification Lambda!
        Resource  = module.send_notification_lambda.arn,
        InputPath = "$.CheckResult",
        End       = true
      },
      EndOnDemand = {
        Type = "Succeed"
      }
    }
  })

  # This state machine needs to invoke two lambdas
  depends_on = [
    aws_iam_role_policy_attachment.on_demand_dynamodb_attachment,
    # The main attachment already includes the send_notification_lambda
    aws_iam_role_policy_attachment.sfn_lambda_attachment
  ]
} 