terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.8.0"
    }
  }
}

provider "vault" {
  address = "https://vault.cosmos.cboxlab.com"
}

