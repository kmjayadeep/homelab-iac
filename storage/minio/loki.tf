resource "minio_s3_bucket" "loki-cosmos-chunks" {
  acl    = "private"
  bucket = "loki-cosmos-chunks"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_s3_bucket" "loki-cosmos-ruler" {
  acl    = "private"
  bucket = "loki-cosmos-ruler"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_s3_bucket" "loki-cosmos-admin" {
  acl    = "private"
  bucket = "loki-cosmos-admin"

  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_iam_user" "loki" {
  name = "loki"
}

resource "minio_iam_policy" "loki-policy" {
  name = "loki-policy"
  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ]
      Effect = "Allow"
      Resource = [
        "${minio_s3_bucket.loki-cosmos-chunks.arn}",
        "${minio_s3_bucket.loki-cosmos-chunks.arn}/*",
        "${minio_s3_bucket.loki-cosmos-ruler.arn}",
        "${minio_s3_bucket.loki-cosmos-ruler.arn}/*",
        "${minio_s3_bucket.loki-cosmos-admin.arn}",
        "${minio_s3_bucket.loki-cosmos-admin.arn}/*"
      ]
    }]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "loki" {
  user_name   = minio_iam_user.loki.id
  policy_name = minio_iam_policy.loki-policy.id
}

resource "minio_iam_service_account" "loki" {
  target_user = minio_iam_user.loki.name
  policy      = minio_iam_policy.loki-policy.policy
}

output "loki_access_key" {
  value     = minio_iam_service_account.loki.access_key
  sensitive = true
}

output "loki_secret_key" {
  value     = minio_iam_service_account.loki.secret_key
  sensitive = true
}
