resource "aws_iam_role" "ssm_role_ec2" {
  name = "ssm-role-for-EC2-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_ec2_attach" {
  role       = aws_iam_role.ssm_role_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "django-app-ssm-profile"
  role = aws_iam_role.ssm_role_ec2.name

}

resource "aws_iam_role_policy" "read_db_params" {
  name = "ec2-read-password-policy"
  role = aws_iam_role.ssm_role_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = [aws_ssm_parameter.djangoapp_db_password.arn]
      },
    ]
  })
}