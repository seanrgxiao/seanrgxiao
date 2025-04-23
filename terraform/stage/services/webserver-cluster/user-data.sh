#!/bin/bash

exec > /var/log/user-data.log 2>&1
set -x

echo "Hello, World" >> index.html
echo "${db_address}" >> index.html
echo "${db_port}" >> index.html
echo "${server_port}" >> index.html
nohup busybox httpd -f -p ${server_port} &
