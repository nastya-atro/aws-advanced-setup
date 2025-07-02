# 1. Получаем ARN SQS-очереди из выходных данных стека SAM
data "aws_cloudformation_stack" "sam_stack" {
  name = "earthquake-import-service"
}

# 2. Архивируем код Lambda-функции из директории check-lambdas
data "archive_file" "sqs_consumer_code" {
  type        = "zip"
  source_dir  = "../check-lambdas/sqs-consumer"
  output_path = "${path.module}/sqs_consumer.zip"
}

# 3. IAM-роль для Lambda-функции
resource "aws_iam_role" "sqs_consumer" {
  name = "sqs-event-consumer-role"

  # Эта политика разрешает сервису Lambda использовать данную роль.
  # Именно этот блок отсутствовал.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 4. Прикрепляем политики к IAM-роли

# Политика для базового выполнения Lambda (логи в CloudWatch)
resource "aws_iam_role_policy_attachment" "sqs_consumer_basic_execution" {
  role       = aws_iam_role.sqs_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Политика, разрешающая чтение из SQS-очереди
resource "aws_iam_policy" "sqs_consumer_read_policy" {
  name = "sqs-event-consumer-read-policy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Effect   = "Allow"
      Resource = data.aws_cloudformation_stack.sam_stack.outputs["EarthquakeMetadataQueueArn"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_consumer_read_attachment" {
  role       = aws_iam_role.sqs_consumer.name
  policy_arn = aws_iam_policy.sqs_consumer_read_policy.arn
}

# 5. Сама Lambda-функция
resource "aws_lambda_function" "sqs_consumer" {
  function_name = "SqsEventConsumer"
  role          = aws_iam_role.sqs_consumer.arn

  filename         = data.archive_file.sqs_consumer_code.output_path
  source_code_hash = data.archive_file.sqs_consumer_code.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs20.x"

  timeout     = 30
  memory_size = 128

  depends_on = [
    aws_iam_role_policy_attachment.sqs_consumer_basic_execution,
    aws_iam_role_policy_attachment.sqs_consumer_read_attachment
  ]
}

# 6. Триггер, который связывает SQS и Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = data.aws_cloudformation_stack.sam_stack.outputs["EarthquakeMetadataQueueArn"]
  function_name    = aws_lambda_function.sqs_consumer.arn
  batch_size       = 10
  enabled          = true
}