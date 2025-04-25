resource "aws_instance" "example" {
  ami           = "ami-01938df366ac2d954"
  instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-up-and-running-state-by-seanrgxiao"
    key    = "workspaces-example/terraform-single-vm.tfstate"
    region = "ap-southeast-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}
