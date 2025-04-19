#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

yum install -y busybox

mkdir -p /var/www/html
echo "Hello, World from ASG" > /var/www/html/index.html

nohup busybox httpd -f -p ${var.server_port} -h /var/www/html &
