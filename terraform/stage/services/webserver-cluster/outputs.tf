output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer"
}
output "alb_log_bucket" {
  value = module.s3.alb_log_bucket
  description = "The bucket for storing alb log"
}