terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "aws-3tier-app/terraform.tfstate"
    region         = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

