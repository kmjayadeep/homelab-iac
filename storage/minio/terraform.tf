terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.41.1"
    }
  }
  required_version = "~> 1.15"
}

provider "minio" {
  minio_server = "minio.cosmos.cboxlab.com"
  minio_region = "us-west-000"
  minio_ssl    = true
}
