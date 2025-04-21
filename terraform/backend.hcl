# backend.hcl
bucket         = "terraform-up-and-running-state-by-seanrgxiao"
region         = "ap-southeast-1"
dynamodb_table = "terraform-up-and-running-locks-by-seanrgxiao"
encrypt        = true