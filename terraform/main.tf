terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "purrimeter-tfstate-981026211833"
    key          = "global/terraform.tfstate"
    region       = "ca-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_s3_bucket" "location_data" {
  bucket = "purrimeter-location-data-981026211833"
}

resource "aws_iam_role" "fetch_lambda" {
  name = "purrimeter-fetch-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "fetch_lambda" {
  name = "purrimeter-fetch-lambda-policy"
  role = aws_iam_role.fetch_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.location_data.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

variable "image_uri" {
  description = "ECR image URI with digest, passed in from CI"
  type        = string
}

resource "aws_lambda_function" "fetch" {
  function_name = "purrimeter-fetch"
  role          = aws_iam_role.fetch_lambda.arn
  package_type  = "Image"
  image_uri     = var.image_uri
  timeout       = 30

  environment {
    variables = {
      DATA_BUCKET = aws_s3_bucket.location_data.bucket
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_15_min" {
  name                = "purrimeter-fetch-schedule"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "fetch" {
  rule = aws_cloudwatch_event_rule.every_15_min.name
  arn  = aws_lambda_function.fetch.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_15_min.arn
}
