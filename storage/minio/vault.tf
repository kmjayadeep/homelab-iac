resource "minio_s3_bucket" "vault_backups" {
  acl    = "private"
  bucket = "vault-cosmos-backups"
}

resource "minio_ilm_policy" "vault_backups" {
  bucket = minio_s3_bucket.vault_backups.bucket

  rule {
    id         = "expire-daily-raft-snapshots-after-45-days"
    filter     = "titania/daily/"
    expiration = "45d"
  }

  rule {
    id         = "expire-weekly-raft-snapshots-after-180-days"
    filter     = "titania/weekly/"
    expiration = "180d"
  }

  rule {
    id         = "expire-monthly-raft-snapshots-after-365-days"
    filter     = "titania/monthly/"
    expiration = "365d"
  }
}

resource "minio_iam_user" "vault_backup" {
  name = "vault-backup"
}

resource "minio_iam_policy" "vault_backup" {
  name = "vault-backup"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [minio_s3_bucket.vault_backups.arn]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = ["${minio_s3_bucket.vault_backups.arn}/*"]
      },
    ]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "vault_backup" {
  user_name   = minio_iam_user.vault_backup.id
  policy_name = minio_iam_policy.vault_backup.id
}

resource "minio_iam_service_account" "vault_backup" {
  target_user = minio_iam_user.vault_backup.name
  policy      = minio_iam_policy.vault_backup.policy
}

output "vault_backup_access_key" {
  value     = minio_iam_service_account.vault_backup.access_key
  sensitive = true
}

output "vault_backup_secret_key" {
  value     = minio_iam_service_account.vault_backup.secret_key
  sensitive = true
}
