resource "aws_ssm_parameter" "djangoapp_db_password" {
  name  = "/djangoapp/db/password"
  type  = "SecureString"
  value = random_password.db_password.result
}