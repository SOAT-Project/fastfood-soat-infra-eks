terraform {
  backend "s3" {
    bucket = "bucket-eks-fastfood"
    key    = "eks/terraform.tfstate"
    region = "sa-east-1"
  }
}
