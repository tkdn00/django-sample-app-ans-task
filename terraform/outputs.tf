output "app_instance_id" {
  value = values(aws_instance.app_instance)[*].id
}

output "db_instance_id" {
  value = aws_instance.db_instance.id
}

output "alb_dns_name" {
  value = aws_lb.djangoapp_lb.dns_name
}