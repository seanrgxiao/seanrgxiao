resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-by-seanrgxiao"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks-by-seanrgxiao"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "alb_access_logs" {
  bucket = "alb-access-logs-seanrgxiao"

  # 启用生命周期管理，日志30天后删除
  lifecycle {
    prevent_destroy = true
  }

  # S3 Bucket策略，用来允许 ALB 写日志到这个桶
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowALBAccessLogs",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::alb-access-logs-seanrgxiao/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
          "AWS:SourceArn": "arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/*"
        }
      }
    }
  ]
}
POLICY
}
# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default_alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_lifecycle" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    id     = "delete-old-alb-logs"
    status = "Enabled"

    expiration {
      days = 30  # 设置30天后删除日志
    }

    filter {
      prefix = "alb-logs/"  # 限定此规则只适用于日志文件
    }
  }
}