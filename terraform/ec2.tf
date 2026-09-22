data "aws_ami" "djangoapp_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
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

resource "aws_instance" "app_instance1" {
  ami                    = data.aws_ami.djangoapp_ami.id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.app_instance_sg.id]

  tags = {
    Name = "App instance 1"
  }
}

resource "aws_instance" "app_instance2" {
  ami                    = data.aws_ami.djangoapp_ami.id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.app_instance_sg.id]

  tags = {
    Name = "App instance 2"
  }
}

resource "aws_instance" "db_instance" {
  ami                    = data.aws_ami.djangoapp_ami.id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "Database instance"
  }
}