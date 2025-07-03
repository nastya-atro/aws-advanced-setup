# ==============================================================================
# STEP FUNCTION WORKFLOW
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IAM Role for the State Machine
#    This role allows the state machine to invoke our Lambda functions.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "step_function_execution_role" {
  name = "step-function-execution-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "step_function_lambda_policy" {
  name   = "step-function-lambda-invoke-policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "lambda:InvokeFunction",
      Effect   = "Allow",
      Resource = [
        module.get_locations_lambda.arn,
        module.check_location_lambda.arn,
        module.send_notification_lambda.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_lambda_attachment" {
  role       = aws_iam_role.step_function_execution_role.name
  policy_arn = aws_iam_policy.step_function_lambda_policy.arn
}

# ------------------------------------------------------------------------------
# 2. State Machine Definition
#    This is the core logic of our workflow.
# ------------------------------------------------------------------------------
resource "aws_sfn_state_machine" "notify_locations_workflow" {
  name     = "NotifyLocationsWorkflow"
  role_arn = aws_iam_role.step_function_execution_role.arn

  definition = jsonencode({
    Comment = "A workflow to check locations for a feature and send notifications.",
    StartAt = "GetLocations"
    States = {
      GetLocations = {
        Type        = "Task",
        Resource    = module.get_locations_lambda.arn,
        Next        = "ProcessLocations",
        ResultPath  = "$.Payload"
      },
      ProcessLocations = {
        Type       = "Map",
        ItemsPath  = "$.Payload.locations",
        MaxConcurrency = 3,
        Parameters = {
          "location.$"   : "$$.Map.Item.Value",
          "feature_id.$" : "$.Payload.feature_id"
        },
        Iterator   = {
          StartAt = "CheckSingleLocation",
          States  = {
            CheckSingleLocation = {
              Type       = "Task",
              Resource   = module.check_location_lambda.arn,
              ResultPath = "$.CheckResult",
              Next       = "ShouldSendNotification"
            },
            ShouldSendNotification = {
              Type    = "Choice",
              Choices = [
                {
                  Variable   = "$.CheckResult.status",
                  StringEquals = "success",
                  Next       = "SendNotification"
                }
              ],
              Default = "LocationCheckFailed"
            },
            SendNotification = {
              Type       = "Task",
              Resource   = module.send_notification_lambda.arn,
              InputPath  = "$.CheckResult",
              End        = true
            },
            LocationCheckFailed = {
              Type = "Succeed"
            }
          }
        },
        End       = true
      }
    }
  })

  depends_on = [ aws_iam_role_policy_attachment.sfn_lambda_attachment ]
}

# ==============================================================================
# LAMBDA FUNCTIONS FOR THE WORKFLOW (using our new module)
# ==============================================================================

module "get_locations_lambda" {
  source           = "./modules/lambda"
  function_name    = "GetLocationsHandler"
  filename         = "${path.root}/../artifacts/GetLocationsHandler.zip"
  source_code_hash = filebase64sha256("${path.root}/../artifacts/GetLocationsHandler.zip")
  environment_variables = {
    DB_HOST        = aws_db_instance.main.address
    DB_PORT        = aws_db_instance.main.port
    DB_NAME        = aws_db_instance.main.db_name
    DB_SECRET_NAME = aws_secretsmanager_secret.db_credentials.name
  }
  vpc_subnet_ids         = aws_subnet.private[*].id
  vpc_security_group_ids = [aws_security_group.lambda.id]
}

# Attach existing Secrets Manager policy to get_locations_lambda role
resource "aws_iam_role_policy_attachment" "get_locations_secrets_attachment" {
  role       = module.get_locations_lambda.role_name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}



data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # We construct the DynamoDB table ARN because the SAM stack only outputs the table name.
  earthquake_data_table_arn = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${data.aws_cloudformation_stack.sam_stack.outputs["EarthquakeDataTableName"]}"
}

module "check_location_lambda" {
  source           = "./modules/lambda"
  function_name    = "CheckLocationHandler"
  filename         = "${path.root}/../artifacts/CheckLocationHandler.zip"
  source_code_hash = filebase64sha256("${path.root}/../artifacts/CheckLocationHandler.zip")
}

# Define the policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_read_policy" {
  name = "dynamodb-read-earthquake-data-policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "dynamodb:GetItem",
      Effect   = "Allow",
      Resource = local.earthquake_data_table_arn
    }]
  })
}

# Attach the policy to the check_location_lambda role
resource "aws_iam_role_policy_attachment" "check_location_dynamodb_attachment" {
  role       = module.check_location_lambda.role_name
  policy_arn = aws_iam_policy.dynamodb_read_policy.arn
}

resource "aws_ses_email_identity" "source_email" {
  email = "a.atroshchanka.work@gmail.com"
}

resource "aws_iam_policy" "ses_send_policy" {
  name = "ses-send-email-policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "ses:SendEmail",
      Effect   = "Allow",
      Resource = aws_ses_email_identity.source_email.arn
    }]
  })
}

module "send_notification_lambda" {
  source               = "./modules/lambda"
  function_name        = "SendNotificationHandler"
  filename             = "${path.root}/../artifacts/SendNotificationHandler.zip"
  source_code_hash     = filebase64sha256("${path.root}/../artifacts/SendNotificationHandler.zip")
  additional_policy_arns = {
    ses_send_policy = aws_iam_policy.ses_send_policy.arn
  }
  environment_variables = {
    SOURCE_EMAIL = aws_ses_email_identity.source_email.email
  }
} 