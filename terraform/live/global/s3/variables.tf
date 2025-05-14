variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "alb_bucket_name" {
  description = "Bucket name for ALB access log"
  type        = string
  default     = "alb-access-logs-seanrgxiao"
}
