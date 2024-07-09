terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.43.0, <5.49.0, !=5.47.0" # version aws >=; <; !=
    }
  }
  required_version = "~>1.8.0" # version de Terraform ~> :permite cualquier versión de Terraform 1.x.x que sea mayor o igual a 1.8.0, pero que no llegue a 1.9.0.
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

