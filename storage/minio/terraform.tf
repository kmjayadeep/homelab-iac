terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.5.1"
    }
  }
  required_version = "~> 1.15"
}

provider "minio" {
  minio_server = "minio.cosmos.cboxlab.com"
  minio_ssl    = true
}
