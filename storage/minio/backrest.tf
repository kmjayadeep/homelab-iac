resource "minio_iam_user" "backrest" {
  name = "backrest"
}

resource "minio_iam_user_policy_attachment" "backrest-nuc" {
  user_name   = minio_iam_user.backrest.id
  policy_name = minio_iam_policy.nuc-policy.id
}

resource "minio_iam_service_account" "backrest-nuc-restic" {
  target_user = minio_iam_user.backrest.name
  policy      = minio_iam_policy.nuc-policy.policy
}

output "backrest_nuc_access_key" {
  value     = minio_iam_service_account.backrest-nuc-restic.access_key
  sensitive = true
}

output "backrest_nuc_secret_key" {
  value     = minio_iam_service_account.backrest-nuc-restic.secret_key
  sensitive = true
}
