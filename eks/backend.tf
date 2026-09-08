terraform {
  backend "s3" {
    bucket  = "terraform-eks-state-arun-2026-0905"
    key     = "eks/dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
