terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.8.0"
    }
  }
}

provider "vault" {
  address = "https://vault.cosmos.cboxlab.com"
}

