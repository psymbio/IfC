terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

locals {
  lambda_function_name = "upload_hello_txt_lambda"
}

resource "aws_s3_bucket" "this" {
  bucket = "my-s3-bucket"
  acl    = "private"
}

resource "aws_sns_topic" "this" {
  name = "updated_topic"
}

resource "aws_lambda_function" "s3_handler" {
  function_name = "${local.lambda_function_name}_s3"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.s3Handler"
  runtime       = "nodejs14.x"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.this.bucket
      TOPIC_ARN   = aws_sns_topic.this.arn
    }
  }
}

resource "aws_lambda_function" "sns_handler" {
  function_name = "${local.lambda_function_name}_sns"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.snsHandler"
  runtime       = "nodejs14.x"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.this.bucket
      TOPIC_ARN   = aws_sns_topic.this.arn
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_handler.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_handler.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_handler.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Action: "sts:AssumeRole",
        Effect: "Allow",
        Principal: {
          Service: "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect: "Allow",
        Resource: "arn:aws:logs:*:*:*"
      },
      {
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect: "Allow",
        Resource: [
          "${aws_s3_bucket.this.arn}",
          "${aws_s3_bucket.this.arn}/*"
        ]
      },
      {
        Action: [
          "sns:Publish"
        ],
        Effect: "Allow",
        Resource: "${aws_sns_topic.this.arn}"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.js"
  output_path = "${path.module}/lambda.zip"
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.s3_handler.function_name
}
