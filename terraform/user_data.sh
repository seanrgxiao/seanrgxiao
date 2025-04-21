#!/bin/bash
echo 'Hello, test' >> /tmp/user_data.log
sudo echo 'Hello, test3' >> /tmp/user_data.log

exec > /var/log/user-data.log 2>&1
set -x
echo 'Hello, test2' >> /tmp/user_data.log
echo ${var.server_port} >> /tmp/user_data.log
# echo "Hello, World" > user-data.log
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &

# nohup busybox httpd -f -p ${var.server_port} &
