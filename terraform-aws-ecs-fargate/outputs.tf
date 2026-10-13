output "alb_dns_name" {
  value = aws_lb.djangoapp_lb.dns_name
}

output "app_url" {
  value = "http://${aws_lb.djangoapp_lb.dns_name}"
}


output "rds_endpoint" {
  value = aws_db_instance.djangoapp_db.address
}