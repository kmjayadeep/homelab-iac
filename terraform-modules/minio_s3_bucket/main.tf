resource "minio_s3_bucket" "this" {
  bucket = var.name
  acl    = var.acl
}

resource "minio_iam_user" "this" {
  count = var.create_user ? 1 : 0
  name  = "${var.name}-default-user"
}

resource "minio_iam_policy" "this" {
  count = var.create_user ? 1 : 0
  name  = "${var.name}-default-policy"
  policy = jsonencode({
    Statement = [{
      Action = ["s3:*"]
      Effect = "Allow"
      Resource = [
        "${minio_s3_bucket.this.arn}",
        "${minio_s3_bucket.this.arn}/*"
      ]
    }]
    Version = "2012-10-17"
  })
}

resource "minio_iam_user_policy_attachment" "this" {
  count       = var.create_user ? 1 : 0
  user_name   = minio_iam_user.this[0].id
  policy_name = minio_iam_policy.this[0].id
}

resource "minio_iam_service_account" "this" {
  count       = var.create_user ? 1 : 0
  target_user = minio_iam_user.this[0].name
}
