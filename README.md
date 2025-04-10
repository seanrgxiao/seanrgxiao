At chapter 3, we deployed the architecture as below:


ASG



One for team's internal testing(staging)
One for real users can access(production)


Ideally, two environments are nearly identical

In general, we put the code inside of a function and reuse the function
In terraform, we can put code in modules and reuse the module in multiple places


Next, we'll create and use terraform modules by covering the following topics:
	- Module basics
	- Module inputs
	- Module locals
	- Module outputs
	- Module gotchas
	- Module versioning



Module basics

module "Name" {
	source = "source"
	config
	…
}


Name is an identifier to use throughout the TF code to refer to this module
Source is the path where the module code can be found
Config consists of arguments that are specific to that module


Note that whenever add a module or modify the source parameter of a module, we need to run init

Problem:
All of the names are hardcoded.
So, in same AWS account, we'll get name conflict errors
Fix:
Add configurable inputs to the module, so we can behave differently in different environments.



Module inputs

Input variables

File variables.tf


variable "cluster_name" {
	description = "The name to use for all the cluster resources"
	type = string
}


File main.tf

resource "aws_security_group" "alb" {
	name = "${var.cluster_name}-alb"
	ingress {
		from_port = 80
		to_port = 80
		protocal = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}


![image](https://github.com/user-attachments/assets/c253eb4c-411d-402e-8add-9759c57fc921)
