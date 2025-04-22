terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-up-and-running-state-by-seanrgxiao"
    key            = "global/s3/terraform-s3.tfstate"
    # key = "workspaces-example/terraform.tfstate"
    region         = "ap-southeast-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks-by-seanrgxiao"
    encrypt        = true
  }
}