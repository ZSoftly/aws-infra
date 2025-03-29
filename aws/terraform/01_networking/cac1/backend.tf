terraform {
  backend "s3" {
    bucket = "zsoftly-poc-sandbox-terraform-cac1"
    key    = "aws/terraform/01_networking/cac1"
    region = "ca-central-1"
  }
}