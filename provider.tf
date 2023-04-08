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

// aws provider will setup all lambda things and iam user/permissions
provider "aws" {
  # Configuration options
}

// vault provider will setup all needed configuration on vault side
provider "vault" {
  address = var.vault_addr
  token = var.vault_root_token
}