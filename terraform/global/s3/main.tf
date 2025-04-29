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
  bucket = var.alb_bucket_name

  # 启用生命周期管理，日志30天后删除
  lifecycle {
    prevent_destroy = true
  }
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

# Set appropriate bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_access_logs.name

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Create bucket policy to allow ALB to write logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        principal = {
          type = "AWS"
          identifiers = ["${data.aws_caller_identity.current.account_id}"]
        }
        # Principal = {
        #   AWS = "arn:aws:iam::${var.elb_account_ids[data.aws_region.current.name]}:root"
        # }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_access_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

# resource "aws_s3_bucket_policy" "alb_access_logs_policy" {
#   bucket = aws_s3_bucket.alb_access_logs.bucket
#   policy = data.aws_iam_policy_document.allow_access_from_alb.json
# }

# data "aws_iam_policy_document" "allow_access_from_alb" {
#   statement {
#     principals {
#       type = "AWS"
#       identifiers = ["${data.aws_caller_identity.current.account_id}"]
#     }
#     actions = [
#       "s3:*"
#     ]
#     resources = [
#       aws_s3_bucket.alb_access_logs.arn,
#       "${aws_s3_bucket.alb_access_logs.arn}/*",
#     ]
#   }
# }

resource "aws_iam_policy" "alb_s3_access_policy" {
  name        = "ALBS3AccessPolicy"
  description = "Policy to allow ALB to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "arn:aws:s3:::${var.alb_bucket_name}/*"  # 允许访问存储桶中的所有对象
      }
    ]
  })
}

resource "aws_iam_role" "alb_s3_role" {
  name               = "alb-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_s3_policy_attachment" {
  policy_arn = aws_iam_policy.alb_s3_access_policy.arn
  role       = aws_iam_role.alb_s3_role.name
}

resource "aws_s3_bucket_public_access_block" "s3_alb_logs_block" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
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