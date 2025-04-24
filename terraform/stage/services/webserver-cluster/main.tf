provider "aws" {
  region = "ap-southeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webserver-stage"
  db_remote_state_bucket = "terraform-up-and-running-state-by-seanrgxiao-stage"
  db_remote_state_key = "stage/services/webserver-cluster/terraform-webserver.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}
# terraform {
#   backend "s3" {
#     # Replace this with your bucket name!
#     bucket         = "terraform-up-and-running-state-by-seanrgxiao"
#     key            = "stage/services/webserver-cluster/terraform-webserver.tfstate"
#     region         = "ap-southeast-1"

#     # Replace this with your DynamoDB table name!
#     dynamodb_table = "terraform-up-and-running-locks-by-seanrgxiao"
#     encrypt        = true
#   }
# }
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket         = var.db_remote_state_bucket
      key            = var.db_remote_state_key
    region         = "ap-southeast-1"
  }
}