resource "aws_ssm_parameter" "djangoapp_db_password" {
  name  = "/djangoapp/db/password"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "djangoapp_db_name" {
  name  = "/djangoapp/db/name"
  type  = "String"
  value = var.db_name
}

resource "aws_ssm_parameter" "djangoapp_db_user" {
  name  = "/djangoapp/db/user"
  type  = "String"
  value = var.db_user
}

resource "random_password" "django_secret_key" {
  length  = 50
  special = false
}

resource "aws_ssm_parameter" "django_secret_key" {
  name  = "/djangoapp/app/secret_key"
  type  = "SecureString"
  value = random_password.django_secret_key.result
}

resource "aws_ssm_parameter" "github_token" {
  name  = "/djangoapp/github/token"
  type  = "SecureString"
  value = var.github_token
}

locals {
  ansible_source_info = jsonencode({
    owner      = "tkdn00"
    repository = "django-sample-app-ans-task"
    path       = "ansible"
    getOptions = "branch:main"
    tokenInfo  = "{{ssm-secure:${aws_ssm_parameter.github_token.name}}}"
  })
}

resource "aws_ssm_association" "db_setup" {
  association_name = "djangoapp-db-setup"
  name             = "AWS-ApplyAnsiblePlaybooks"

  targets {
    key    = "tag:Role"
    values = ["db"]
  }

  parameters = {
    SourceType          = "GitHub"
    SourceInfo          = local.ansible_source_info
    InstallDependencies = "True"
    PlaybookFile        = "db.yml"
    ExtraVariables      = "SSM=True"
    Check               = "False"
    Verbose             = "-v"
  }

  wait_for_success_timeout_seconds = 900
}


resource "aws_ssm_association" "deploy" {
  association_name = "djangoapp-deploy"
  name             = "AWS-ApplyAnsiblePlaybooks"
  max_concurrency  = "1"

  targets {
    key    = "tag:Role"
    values = ["app"]
  }

  parameters = {
    SourceType          = "GitHub"
    SourceInfo          = local.ansible_source_info
    InstallDependencies = "True"
    PlaybookFile        = "deploy.yml"
    ExtraVariables      = "SSM=True db_host=${aws_instance.db_instance.private_ip} alb_dns=${aws_lb.djangoapp_lb.dns_name}"
    Check               = "False"
    Verbose             = "-v"
  }

  wait_for_success_timeout_seconds = 1800

  depends_on = [aws_ssm_association.db_setup]
}
