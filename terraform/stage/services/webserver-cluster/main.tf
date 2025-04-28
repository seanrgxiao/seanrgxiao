provider "aws" {
  region = "ap-southeast-1"
}

# module "s3" {
#   source = "../../../global/s3"
# }

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webserver-stage"
  db_remote_state_bucket = "terraform-up-and-running-state-by-seanrgxiao"
  db_remote_state_key    = "stage/services/webserver-cluster/terraform-webserver.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
  s3_bucket_alb_log = "alb-access-logs-seanrgxiao"

  # account_id = data.aws_caller_identity.current.account_id
}
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = module.webserver_cluster.db_remote_state_bucket
    key    = module.webserver_cluster.db_remote_state_key
    region = "ap-southeast-1"
  }
}
