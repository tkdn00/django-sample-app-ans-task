data "aws_ami" "djangoapp_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = var.aws_ami_pattern
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# resource "aws_instance" "app_instance1" {
#   ami                    = data.aws_ami.djangoapp_ami.id
#   instance_type          = "t3.micro"
#   iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
#   subnet_id              = aws_subnet.private1.id
#   vpc_security_group_ids = [aws_security_group.app_instance_sg.id]

#   tags = {
#     Name = "App instance 1"
#   }
# }

# resource "aws_instance" "app_instance2" {
#   ami                    = data.aws_ami.djangoapp_ami.id
#   instance_type          = "t3.micro"
#   iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
#   subnet_id              = aws_subnet.private2.id
#   vpc_security_group_ids = [aws_security_group.app_instance_sg.id]

#   tags = {
#     Name = "App instance 2"
#   }
# }


resource "aws_instance" "app_instance" {
  for_each = local.app_instances

  ami                    = data.aws_ami.djangoapp_ami.id
  instance_type          = var.app_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.app_instance_sg.id]
  subnet_id              = each.value.subnet_id

  tags = {
    Name = "App instance ${each.key}"
    Role = "app"
  }
}

resource "aws_instance" "db_instance" {
  ami                    = data.aws_ami.djangoapp_ami.id
  instance_type          = var.db_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "Database instance"
    Role = "db"
  }
}

locals {
  app_instances = {
    instance1 = {
      subnet_id = aws_subnet.private1.id
    }
    instance2 = {
      subnet_id = aws_subnet.private2.id
    }
  }
}