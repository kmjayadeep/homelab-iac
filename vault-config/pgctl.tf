# pgctl creates database passwords. Exact paths would need an apply for every
# new database, so this is a documented prefix exception (see PATHS.md). It can
# write secrets and read metadata, but can never read a password.
resource "vault_policy" "pgctl" {
  name = "pgctl"

  policy = <<-EOT
    path "${vault_mount.homelab_kv.path}/data/services/postgresql/*" {
      capabilities = ["create", "update"]
    }

    path "${vault_mount.homelab_kv.path}/metadata/services/postgresql/*" {
      capabilities = ["create", "update", "read", "list"]
    }
  EOT
}

resource "vault_approle_auth_backend_role" "pgctl" {
  backend                 = vault_auth_backend.approle.path
  role_name               = "pgctl"
  bind_secret_id          = true
  secret_id_num_uses      = 0
  secret_id_ttl           = 0
  token_policies          = [vault_policy.pgctl.name]
  token_no_default_policy = true
  token_type              = "service"
  token_ttl               = 900
  token_max_ttl           = 3600
}
