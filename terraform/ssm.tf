resource "aws_s3_bucket" "playbooks_bucket" {
  bucket = "s3-for-djanjoapp-playbooks"

  tags = {
    Name        = "My bucket"
  }
}
