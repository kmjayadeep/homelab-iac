resource "minio_s3_bucket" "valheim-backup" {
  acl    = "private"
  bucket = "valheim-backup"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_iam_user" "valheim" {
  name = "valheim"
}

resource "minio_iam_policy" "valheim-backup-policy" {
  name = "valheim-backup-policy"
  policy = jsonencode({
    Statement = [{
      Action   = ["s3:*"]
      Effect   = "Allow"
      Resource = ["${minio_s3_bucket.valheim-backup.arn}", "${minio_s3_bucket.valheim-backup.arn}/*"]
    }]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "valheim" {
  user_name   = minio_iam_user.valheim.id
  policy_name = minio_iam_policy.valheim-backup-policy.id
}

resource "minio_iam_service_account" "valheim-restic" {
  target_user = minio_iam_user.valheim.name
  policy      = minio_iam_policy.valheim-backup-policy.policy
}

output "valheim_access_key" {
  value     = minio_iam_service_account.valheim-restic.access_key
  sensitive = true
}

output "valheim_secret_key" {
  value     = minio_iam_service_account.valheim-restic.secret_key
  sensitive = true
}
