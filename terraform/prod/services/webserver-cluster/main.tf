provider "aws" {
  region = "ap-southeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-up-and-running-state-by-seanrgxiao"
    key            = "prod/services/webserver-cluster/terraform-webserver.tfstate"
    region         = "ap-southeast-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks-by-seanrgxiao"
    encrypt        = true
  }
}
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket         = "terraform-up-and-running-state-by-seanrgxiao"
      key            = "prod/data-stores/mysql/terraform.tfstate"
    region         = "ap-southeast-1"
  }
}