terraform {
  backend "s3" {
    bucket         = "eks-it-tools-state"
    key            = "infra"
    region         = "eu-west-2"
    dynamodb_table = "eks-locks"
    encrypt        = true
  }
}
