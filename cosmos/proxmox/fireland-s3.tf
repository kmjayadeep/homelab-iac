module "fireland_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "fireland-valaheim-backup"
  create_user = true
}
