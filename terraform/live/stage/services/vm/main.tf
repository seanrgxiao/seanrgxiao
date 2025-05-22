# 指定 Terraform 提供商
provider "aws" {
  region = "us-east-1"  # 你可以根据需要修改为你想使用的 AWS 区域
}

# 创建一个安全组
resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 创建一个 EC2 实例
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"  # 你需要替换为适用于你所在区域的 AMI ID
  instance_type = "t2.micro"               # 你可以根据需求修改实例类型
  key_name      = "your-key-name"          # 你的 SSH 密钥名称
  security_groups = [aws_security_group.example.name]

  tags = {
    Name = "ExampleInstance"
  }
}

# 输出 EC2 实例的公共 IP
output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
