terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.62.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.14.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

provider "vault" {
  address = var.vault_addr
  token = var.vault_root_token
}