provider "aws" {
  region = "ap-southeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webserver-stage"
  db_remote_state_bucket = "terraform-up-and-running-state-by-seanrgxiao-stage"
  db_remote_state_key    = "stage/services/webserver-cluster/terraform-webserver.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "ap-southeast-1"
  }
}
