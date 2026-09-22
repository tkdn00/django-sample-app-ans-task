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