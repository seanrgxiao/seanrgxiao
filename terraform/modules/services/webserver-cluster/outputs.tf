output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}
output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the sg attached to the lb"
}
output "db_remote_state_bucket" {
  value = var.db_remote_state_bucket
}
output "db_remote_state_key" {
  value = var.db_remote_state_key
}