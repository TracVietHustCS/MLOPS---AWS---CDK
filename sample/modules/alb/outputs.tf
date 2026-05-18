
output "alb_id" {
  description = "The ID of the load balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener (if certificate is provided)"
  value       = var.certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "target_group_arns" {
  description = "Map of target group ARNs"
  value       = { for k, tg in aws_lb_target_group.main : k => tg.arn }
}

output "target_group_names" {
  description = "Map of target group names"
  value       = { for k, tg in aws_lb_target_group.main : k => tg.name }
}
