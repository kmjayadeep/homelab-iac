terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.9.0"
    }
  }
}

provider "vault" {
  address = "https://vault.cosmos.cboxlab.com"
}

