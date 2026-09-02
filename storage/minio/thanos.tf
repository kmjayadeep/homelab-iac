resource "minio_s3_bucket" "thanos-cosmos" {
  acl    = "private"
  bucket = "thanos-cosmos"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_iam_user" "thanos" {
  name = "thanos"
}

resource "minio_iam_policy" "thanos-policy" {
  name = "thanos-policy"
  policy = jsonencode({
    Statement = [{
      Action = ["s3:*"]
      Effect = "Allow"
      Resource = [
        "${minio_s3_bucket.thanos-cosmos.arn}",
        "${minio_s3_bucket.thanos-cosmos.arn}/*"
      ]
    }]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "thanos" {
  user_name   = minio_iam_user.thanos.id
  policy_name = minio_iam_policy.thanos-policy.id
}

resource "minio_iam_service_account" "thanos-restic" {
  target_user = minio_iam_user.thanos.name
  policy      = minio_iam_policy.thanos-policy.policy
}

output "thanos_access_key" {
  value     = minio_iam_service_account.thanos-restic.access_key
  sensitive = true
}

output "thanos_secret_key" {
  value     = minio_iam_service_account.thanos-restic.secret_key
  sensitive = true
}
