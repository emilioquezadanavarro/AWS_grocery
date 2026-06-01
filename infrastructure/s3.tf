resource "aws_s3_bucket" "avatars" {
  bucket = "grocerymate-avatars-eaqn-123"

  tags = {
    Name        = "grocerymate-avatars"
    Environment = "Dev"
  }
}
