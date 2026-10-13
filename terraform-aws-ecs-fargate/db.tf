resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "random_password" "django_secret_key" {
  length  = 50
  special = false
}

resource "aws_ssm_parameter" "djangoapp_db_password" {
  name  = "/djangoapp-ecs/db/password"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "django_secret_key" {
  name  = "/djangoapp-ecs/app/secret_key"
  type  = "SecureString"
  value = random_password.django_secret_key.result
}

resource "aws_db_subnet_group" "djangoapp_db_subnets" {
  name       = "djangoapp-ecs-db-subnets"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  tags = {
    Name = "DB subnet group for djangoapp"
  }
}

resource "aws_db_instance" "djangoapp_db" {
  identifier     = "djangoapp-ecs-db"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_user
  password = random_password.db_password.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.djangoapp_db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "Postgres RDS for djangoapp"
  }
}
