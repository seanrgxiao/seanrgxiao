#!/bin/bash

exec > /var/log/user-data.log 2>&1
set -x
echo "<pre>" >> index.html
echo "Hello, World" >> index.html
echo "${server_port}" >> index.html
echo "</pre>" >> index.html


nohup busybox httpd -f -p ${server_port} &
