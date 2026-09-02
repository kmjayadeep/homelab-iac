resource "minio_s3_bucket" "nuc-backup" {
  acl    = "private"
  bucket = "nuc-backup"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_s3_bucket" "nuc-private-backup" {
  acl    = "private"
  bucket = "nuc-private-backup"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_iam_user" "nuc" {
  name = "nuc"
}

resource "minio_iam_policy" "nuc-policy" {
  name = "nuc-policy"
  policy = jsonencode({
    Statement = [{
      Action = ["s3:*"]
      Effect = "Allow"
      Resource = [
        "${minio_s3_bucket.nuc-backup.arn}",
        "${minio_s3_bucket.nuc-backup.arn}/*",
        "${minio_s3_bucket.nuc-private-backup.arn}",
        "${minio_s3_bucket.nuc-private-backup.arn}/*"
      ]
    }]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "nuc" {
  user_name   = minio_iam_user.nuc.id
  policy_name = minio_iam_policy.nuc-policy.id
}

resource "minio_iam_service_account" "nuc-restic" {
  target_user = minio_iam_user.nuc.name
  policy      = minio_iam_policy.nuc-policy.policy
}

output "nuc_access_key" {
  value     = minio_iam_service_account.nuc-restic.access_key
  sensitive = true
}

output "nuc_secret_key" {
  value     = minio_iam_service_account.nuc-restic.secret_key
  sensitive = true
}
