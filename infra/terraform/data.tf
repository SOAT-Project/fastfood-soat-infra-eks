####
# AWS Caller Identity
####

data "aws_caller_identity" "current" {}


####
# AWS Availability Zones
####

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


####
# AWS ECR Public Authorization Token
####

data "aws_ecrpublic_authorization_token" "token" {
  region = "us-east-1"
}
