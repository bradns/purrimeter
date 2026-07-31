terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "purrimeter-tfstate-981026211833"
    key          = "global/terraform.tfstate"
    region       = "ca-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_s3_bucket" "location_data" {
  bucket = "purrimeter-location-data-981026211833"
}
