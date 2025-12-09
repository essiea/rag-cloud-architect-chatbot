terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "docs" {
  bucket = var.doc_bucket_name
}

resource "aws_dynamodb_table" "vectors" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "doc_id"
  range_key    = "chunk_id"

  attribute {
    name = "doc_id"
    type = "S"
  }

  attribute {
    name = "chunk_id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "rag-chatbot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  name = "rag-chatbot-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.docs.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.vectors.arn
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "ingest_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../app"
  output_path = "${path.module}/../build/ingest.zip"
}

data "archive_file" "query_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../app"
  output_path = "${path.module}/../build/query.zip"
}

resource "aws_lambda_function" "ingest" {
  function_name = "rag-doc-ingest"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  handler       = "lambda_ingest.lambda_handler"
  filename      = data.archive_file.ingest_zip.output_path
  timeout       = 60

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.vectors.name
      DOC_BUCKET     = aws_s3_bucket.docs.bucket
      EMBED_MODEL_ID = var.embed_model_id
    }
  }
}

resource "aws_lambda_function" "query" {
  function_name = "rag-query"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  handler       = "lambda_query.lambda_handler"
  filename      = data.archive_file.query_zip.output_path
  timeout       = 60

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.vectors.name
      EMBED_MODEL_ID = var.embed_model_id
      LLM_MODEL_ID   = var.llm_model_id
    }
  }
}

resource "aws_s3_bucket_notification" "docs_notify" {
  bucket = aws_s3_bucket.docs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ingest.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.docs.arn
}

resource "aws_apigatewayv2_api" "http" {
  name          = "rag-chatbot-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.query.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_chat" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
