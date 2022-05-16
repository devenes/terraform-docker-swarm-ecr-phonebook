terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.61.0"
    }
  }
}

provider "aws" {
  # If you use variables in providers GitHub Actions will not be able to see them
  region = "us-east-1"
}
