#!/bin/bash

exec > /var/log/user-data.log 2>&1
set -x
echo "Hello, World" > user-data.log
echo "Hello, World" > /tmp/index.html
nohup busybox httpd -f -p ${var.server_port} &
