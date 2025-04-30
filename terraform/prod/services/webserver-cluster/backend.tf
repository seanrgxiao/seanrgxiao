terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-by-seanrgxiao"
    key    = "prod/services/webserver-cluster/terraform-webserver.tfstate"
    region = "ap-southeast-1"
  }
}