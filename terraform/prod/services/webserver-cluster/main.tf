provider "aws" {
  region = "ap-southeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webserver-prod"
  db_remote_state_bucket = "terraform-up-and-running-state-by-seanrgxiao"
  db_remote_state_key    = "prod/services/webserver-cluster/terraform-webserver.tfstate"

  instance_type = "m4.large"
  min_size      = 2
  max_size      = 10
  s3_bucket_alb_log = "alb-access-logs-seanrgxiao"
}
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = module.webserver_cluster.db_remote_state_bucket
    key    = module.webserver_cluster.db_remote_state_key
    region = "ap-southeast-1"
  }
}
terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-by-seanrgxiao"
    key    = "prod/services/webserver-cluster/terraform-webserver.tfstate"
    region = "ap-southeast-1"
  }
}
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "40 11 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "15 12 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}
