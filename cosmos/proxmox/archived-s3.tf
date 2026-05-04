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
