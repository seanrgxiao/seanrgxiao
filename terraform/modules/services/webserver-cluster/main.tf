data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
resource "aws_launch_template" "example" {
  name_prefix            = "${var.cluster_name}-asg-vm-"
  image_id               = "ami-01938df366ac2d954"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
  }))

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 10

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
  ingress { 
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = local.tcp_protocol
    cidr_blocks = ["172.31.23.255/32"]
  }
  ingress { 
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = local.tcp_protocol
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }  
}
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-sg-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
}
resource "aws_lb" "example" {
  name               = "${var.cluster_name}-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
  /*-*/
  access_logs {
    bucket  = var.s3_bucket_alb_log
    prefix  = "alb-logs"
    enabled = true
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-lb-target-group"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
