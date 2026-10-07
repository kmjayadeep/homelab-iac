# Retain backups for retired VMs.
module "windrose_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "windrose-backup"
  create_user = true
}

module "kite_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "kite-backup"
  create_user = true
}

module "valheim_speedrun_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valheim-speedrun-backup"
  create_user = true
}

module "valheim_rivers_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valheim-rivers-backup"
  create_user = true
}

module "openclaw_chinnu_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "openclaw-chinnu-backup"
  create_user = true
}

module "chillyfries_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "chillyfries-valaheim-backup"
  create_user = true
}

module "fireland_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "fireland-valaheim-backup"
  create_user = true
}

module "valkyrie_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valkyrie-valheim-backup"
  create_user = true
}

module "odin_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "odin-valaheim-backup"
  create_user = true
}
