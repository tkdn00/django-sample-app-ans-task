output "app_instance_id" {
  value = values(aws_instance.app_instance)[*].id
}

output "db_instance_id" {
  value = aws_instance.db_instance.id
}

output "alb_dns_name" {
  value = aws_lb.djangoapp_lb.dns_name
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini>"

  content = <<-EOT
    [app]
    %{for name, inst in aws_instance.app_instance~}
    ${inst.id} private_ip=${inst.private_ip}
    %{endfor~}

    [db]
    ${aws_instance.db_instance.id} private_ip=${aws_instance.db_instance.private_ip}

    [all:vars]
    aws_region=${var.aws_region}
    db_host=${aws_instance.db_instance.private_ip}
    alb_dns=${aws_lb.djangoapp_lb.dns_name}
  EOT
}