provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_launch_template" "example" {
  name_prefix = "asg-example-vm-"
  image_id           = "ami-01938df366ac2d954"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data     = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  launch_template {
    id = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

# output "public_ip" {
#   value = aws_instance.example.public_ip
#   description = "The public IP address of the web server"
# }