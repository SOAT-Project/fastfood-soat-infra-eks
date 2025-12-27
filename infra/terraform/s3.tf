resource "aws_s3_bucket" "terraform_state" {
  bucket = "nome-do-seu-bucket-unico-aqui"

  tags = {
    Name = "Terraform State"
  }
}