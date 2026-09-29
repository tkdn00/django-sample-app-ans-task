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