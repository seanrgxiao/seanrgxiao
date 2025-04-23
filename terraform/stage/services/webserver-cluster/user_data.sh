#!/bin/bash

exec > /var/log/user-data.log 2>&1
set -x

echo "Hello, World" >> index.html
echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
echo "${var.server_port}" >> index.html
nohup busybox httpd -f -p ${var.server_port} &
